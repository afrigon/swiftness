//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Alexandre Frigon. All rights reserved.
//

struct AddressRange {
    // inclusive
    let start: Word
    let end: Word
}

struct MirroredAddressRange {
    let from: AddressRange
    let to: AddressRange
}

enum DataUnit: UInt16 {
    case byte = 1
    case kilobyte = 1024
}

class Memory {
    private var data: [Byte]
    
    init(ofSize size: UInt16 = 64, _ unit: DataUnit = .kilobyte) {
        self.data = Array(repeating: 0x00, count: Int(size * unit.rawValue))
    }
    
    func readByte(at address: Word) -> Byte {
        return self.data[address]
    }
    
    func writeByte(_ data: Byte, at address: Word) {
        self.data[address] = data
    }
    
    func readWord(at address: Word) -> Word {
        return self.readByte(at: address).asWord() + self.readByte(at: address + 1).asWord() << 8
    }
    
    func writeWord(_ data: Word, at address: Word) {
        self.writeByte(data.rightByte(), at: address)
        self.writeByte(data.leftByte(), at: address + 1)
    }
}

class CoreProcesingUnitMemory: Memory, StackAccessDelegate {
    private let stackSize: Word = 0x100
    
    private var _stack: Stack
    private var rom: ReadOnlyMemory
    
    var stack: Stack {
        return self._stack
    }
    
    convenience init(with rom: ReadOnlyMemory) {
        self.init(ofSize: 64, .kilobyte, with: rom)
    }
    
    init(ofSize size: UInt16 = 64, _ unit: DataUnit = .kilobyte, with rom: ReadOnlyMemory? = nil) {
        self.rom = rom ?? ReadOnlyMemory()
        self._stack = Stack()
        super.init(ofSize: size, unit)
        
        self._stack.delegate = self
    }
    
    func stack(stack: Stack, didPushByte data: Byte, at address: Word) {
        let absoluteAddress = address + stackSize
        self.writeByte(data, at: absoluteAddress)
    }
    
    func stack(stack: Stack, didPopByteAt address: Word) -> Byte {
        let absoluteAddress = address + stackSize
        return self.readByte(at: absoluteAddress)
    }
    
    func readWordGlitched(at address: Word) -> Word {
        // 6502 hardware bug, instead of reading from 0xC0FF/0xC100 it reads from 0xC0FF/0xC000
        if address.rightByte() == 0xFF {
            return self.readByte(at: address & 0xFF00).asWord() << 8 + self.readByte(at: address)
        } else {
            // regular code
            return self.readWord(at: address)
        }
    }
}

protocol StackAccessDelegate {
    func stack(stack: Stack, didPushByte data: Byte, at address: Word)
    func stack(stack: Stack, didPopByteAt address: Word) -> Byte
}

class Stack {
    var delegate: StackAccessDelegate?
    
    func pushByte(data: Byte, sp: inout Byte) {
        self.delegate?.stack(stack: self, didPushByte: data, at: sp.asWord())
        sp--
    }
    
    func popByte(sp: inout Byte) -> Byte {
        sp++
        return self.delegate?.stack(stack: self, didPopByteAt: sp.asWord()) ?? 0x00
    }
    
    func pushWord(data: Word, sp: inout Byte) {
        self.pushByte(data: data.leftByte(), sp: &sp)
        self.pushByte(data: data.rightByte(), sp: &sp)
    }
    
    func popWord(sp: inout Byte) -> Word {
        return self.popByte(sp: &sp).asWord() + self.popByte(sp: &sp).asWord() << 8
    }
}





class PictureProcesingUnitMemory: Memory {
    
}


// Abstract Memory Region Objects
class MemoryRegion {
    fileprivate let name: String
    fileprivate let range: AddressRange
    fileprivate var mirror: MirroredAddressRange! = nil
    
    init(_ name: String, _ range: AddressRange, _ mirroredRange: MirroredAddressRange? = nil) {
        self.name = name
        self.range = range
        self.mirror = mirroredRange
    }
    
    func applyMirror(for address: Word) -> Word {
        guard self.mirror != nil else {
            return address
        }
        
//        if self.isInMirroredRange(address) {
//            fatalError("Mirrored range not implemented")
//        }
        
        let offset: Word = self.mirror.from.start - self.mirror.to.start
        return self.mirror.from.start + address % offset
    }
    
    func isInRange(_ address: Word) -> Bool {
        return address >= self.range.start && address <= self.range.end
    }
    
    func isInMirroredRange(_ address: Word) -> Bool {
        guard self.mirror != nil else {
            return false
        }
        
        return address >= self.mirror.from.start && address <= self.mirror.from.end
    }
}

class AttachedMemoryRegion: MemoryRegion {
    var memoryMap: Memory!
    
    func readByte(at address: Word) -> Byte {
        guard self.isInRange(address) else { return 0x00 }
        return Byte(self.memoryMap.readByte(at: self.applyMirror(for: address)))
    }
    
    func writeByte(_ data: Byte, at address: Word) {
        guard self.isInRange(address) else { return }
        self.memoryMap.writeByte(data, at: self.applyMirror(for: address))
    }
    
    func readWord(at address: Word) -> Word {
        guard self.isInRange(address) else { return 0x00 }
        return self.memoryMap.readWord(at: self.applyMirror(for: address))
    }
    
    func writeWord(_ data: Word, at address: Word) {
        guard self.isInRange(address) else { return }
        self.memoryMap.writeWord(data, at: self.applyMirror(for: address))
    }
}

class ReadOnlyMemoryRegion: AttachedMemoryRegion {
    override func writeByte(_ data: Byte, at address: Word) {
        return
    }
    
    override func writeWord(_ data: Word, at address: Word) {
        return
    }
}

// CPU Memory Map Objects
class ReadOnlyMemory: ReadOnlyMemoryRegion {
    init() {
        fatalError("ROM not implemented")
//        let range = AddressRange(start: 0x2000, end: 0x4020)
//        let mirror = MirroredAddressRange(from: AddressRange(start: 0x2008, end: 0x4000),
//                                          to: AddressRange(start: 0x2000, end: 0x2008))
//        super.init("PGR-ROM", range, mirror)
//        self.memoryMap = memoryMap
    }
}

// PPU Memory Mapper Objects
class PictureProcessingUnitRandomAccessMemory: AttachedMemoryRegion {
    init(memoryMap: Memory) {
        let range = AddressRange(start: 0x0000, end: 0xFFFF)
        let mirror = MirroredAddressRange(from: AddressRange(start: 0x4000, end: 0xFFFF),
                                          to: AddressRange(start: 0x0000, end: 0x3FFF))
        super.init("PPU RAM", range, mirror)
        self.memoryMap = memoryMap
    }
}
