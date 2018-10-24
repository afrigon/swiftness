//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Alexandre Frigon. All rights reserved.
//

typealias AddressRange = Range<Word>
typealias AddressRangeMirror = (original: Range<Word>, affected: Range<Word>)

enum DataUnit: UInt16 { case byte = 1, kilobyte = 1024 }
enum MemoryAccess { case read, write }
enum CoreProcessingUnitMemorySegment { case ram, stack, rom }
enum PictureProcessingUnitMemorySegment { }

class Memory {
    private var data: [Byte]
    fileprivate var mirrors: [AddressRangeMirror] = [AddressRangeMirror]()
    
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

class CoreProcessingUnitMemory: Memory, StackAccessDelegate {
    private let stackSize: Word = 0x100
    
    private var rom: ReadOnlyMemory
    private var _stack: Stack
    var stack: Stack { return self._stack }
    
    convenience init(with rom: ReadOnlyMemory) {
        self.init(ofSize: 64, .kilobyte, with: rom)
    }
    
    init(ofSize size: UInt16 = 64, _ unit: DataUnit = .kilobyte, with rom: ReadOnlyMemory? = nil) {
        self.rom = rom ?? ReadOnlyMemory()
        self._stack = Stack()
        super.init(ofSize: size, unit)
        
        self._stack.delegate = self
        self.mirrors.append(AddressRangeMirror(original: 0x0000..<0x0800, affected: 0x0800..<0x2000))
        self.mirrors.append(AddressRangeMirror(original: 0x2000..<0x2008, affected: 0x2008..<0x4000))
    }
    
    func stack(stack: Stack, didPushByte data: Byte, at address: Word) {
        let absoluteAddress = address + stackSize
        self.writeByte(data, at: absoluteAddress)
    }
    
    func stack(stack: Stack, didPopByteAt address: Word) -> Byte {
        let absoluteAddress = address + stackSize
        return self.readByte(at: absoluteAddress)
    }
    
    func hasPermission(to right: MemoryAccess = .read, to address: Word, as segment: CoreProcessingUnitMemorySegment = .ram) -> Bool {
        print("Illegal \(String(describing: right)) to \(address.hex()) as \(String(describing: segment))")
        return false // TODO: actually check permissions
    }
    
    func normalize(_ address: Word) -> Word {
        for mirror in self.mirrors {
            if mirror.affected.contains(address) {
                return mirror.original.startIndex - address % UInt16(mirror.original.count)
            }
        }
        return address
    }
    
    override func readByte(at address: Word) -> Byte {
        return super.readByte(at: self.normalize(address))
    }
    
    override func writeByte(_ data: Byte, at address: Word) {
        super.writeByte(data, at: self.normalize(address))
    }
    
    override func readWord(at address: Word) -> Word {
        return super.readWord(at: self.normalize(address))
    }
    
    override func writeWord(_ data: Word, at address: Word) {
        super.writeWord(data, at: self.normalize(address))
    }
    
    func readWordGlitched(at address: Word) -> Word {
        // 6502 hardware bug, instead of reading from 0xC0FF/0xC100 it reads from 0xC0FF/0xC000
        if address.rightByte() == 0xFF {
            return self.readByte(at: address & 0xFF00).asWord() << 8 + self.readByte(at: address)
        }
        return self.readWord(at: address)
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



class ReadOnlyMemory {
    init() {
        fatalError("ROM not implemented")
    }
}



class PictureProcessingUnitMemory: Memory {
    
}




