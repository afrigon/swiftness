//
//  memory.swift
//  swift-nes
//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Frigstudio. All rights reserved.
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

class Memory {
    private var data: [Byte] = Array(repeating: 0x00, count: 0x10000)
    
    fileprivate func readByte(at address: Word) -> Byte {
        return self.data[address]
    }
    
    fileprivate func writeByte(_ data: Byte, at address: Word) {
        self.data[address] = data
    }
    
    fileprivate func readWord(at address: Word) -> Word {
        return Word(self.readByte(at: address)) + Word(self.readByte(at: address + 1) << 8)
    }
    
    fileprivate func writeWord(_ data: Word, at address: Word) {
        self.writeByte(Byte(data & 0xFF), at: address)
        self.writeByte(Byte(data >> 8), at: address + 1)
    }
}

class CoreProcesingUnitMemoryMap: Memory {
    private var _ram: RandomAccessMemory!
    private var _io: InputOutputRegister!
    private var _expansion: ExpansionReadOnlyMemory!
    private var _save: SaveRandomAccessMemory!
    private var _rom: ReadOnlyMemory!
    
    var ram: RandomAccessMemory {
        return self._ram
    }
    var io: InputOutputRegister {
        return self._io
    }
    var epansion: ExpansionReadOnlyMemory {
        return self._expansion
    }
    var save: SaveRandomAccessMemory {
        return self._save
    }
    var rom: ReadOnlyMemory {
        return self._rom
    }
    
    override init() {
        super.init()
        self._ram = RandomAccessMemory(memoryMap: self)
        self._io = InputOutputRegister(memoryMap: self)
        self._expansion = ExpansionReadOnlyMemory(memoryMap: self)
        self._save = SaveRandomAccessMemory(memoryMap: self)
        self._rom = ReadOnlyMemory(memoryMap: self)
    }
}

class PictureProcesingUnitMemoryMap: Memory {
    private var _ppuMemory: PictureProcessingUnitRandomAccessMemory!
    
    var ppuMemory: PictureProcessingUnitRandomAccessMemory {
        return self._ppuMemory
    }
    
    override init() {
        super.init()
        self._ppuMemory = PictureProcessingUnitRandomAccessMemory(memoryMap: self)
    }
}


// Abstract Memory Region Objects
class MemoryRegion {
    fileprivate let name: String
    fileprivate let range: AddressRange
    fileprivate var mirror: MirroredAddressRange! = nil
    
    fileprivate init(_ name: String, _ range: AddressRange, _ mirroredRange: MirroredAddressRange? = nil) {
        self.name = name
        self.range = range
        self.mirror = mirroredRange
    }
    
    fileprivate func applyMirror(for address: Word) -> Word {
        guard self.mirror != nil else {
            return address
        }
        
        if self.isInMirroredRange(address) {
            fatalError("Mirrored range not implemented")
        }
        
        let offset: Word = self.mirror.from.start - self.mirror.to.start
        return address - offset
    }
    
    fileprivate func isInRange(_ address: Word) -> Bool {
        return address >= self.range.start && address <= self.range.end
    }
    
    fileprivate func isInMirroredRange(_ address: Word) -> Bool {
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
        return self.memoryMap.readByte(at: self.applyMirror(for: address))
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
class RandomAccessMemory: AttachedMemoryRegion {
    init(memoryMap: Memory) {
        let range = AddressRange(start: 0x0000, end: 0x1FFF)
        let mirror = MirroredAddressRange(from: AddressRange(start: 0x0800, end: 0x1FFF),
                                          to: AddressRange(start: 0x0000, end: 0x07FF))
        super.init("RAM", range, mirror)
        self.memoryMap = memoryMap
    }
}

class InputOutputRegister: AttachedMemoryRegion {
    init(memoryMap: Memory) {
        let range = AddressRange(start: 0x2000, end: 0x401F)
        let mirror = MirroredAddressRange(from: AddressRange(start: 0x2008, end: 0x3FFF),
                                          to: AddressRange(start: 0x2000, end: 0x2007))
        super.init("IO Registers", range, mirror)
        self.memoryMap = memoryMap
    }
}

class ExpansionReadOnlyMemory: AttachedMemoryRegion {
    init(memoryMap: Memory) {
        fatalError("Expansion ROM not implemented")
        let range = AddressRange(start: 0x2000, end: 0x4020)
        let mirror = MirroredAddressRange(from: AddressRange(start: 0x2008, end: 0x4000),
                                          to: AddressRange(start: 0x2000, end: 0x2008))
        super.init("Expansion ROM", range, mirror)
        self.memoryMap = memoryMap
    }
}

class SaveRandomAccessMemory: AttachedMemoryRegion {
    init(memoryMap: Memory) {
        fatalError("SRAM not implemented")
        let range = AddressRange(start: 0x2000, end: 0x4020)
        let mirror = MirroredAddressRange(from: AddressRange(start: 0x2008, end: 0x4000),
                                          to: AddressRange(start: 0x2000, end: 0x2008))
        super.init("Save RAM", range, mirror)
        self.memoryMap = memoryMap
    }
}

class ReadOnlyMemory: ReadOnlyMemoryRegion {
    init(memoryMap: Memory) {
        fatalError("ROM not implemented")
        let range = AddressRange(start: 0x2000, end: 0x4020)
        let mirror = MirroredAddressRange(from: AddressRange(start: 0x2008, end: 0x4000),
                                          to: AddressRange(start: 0x2000, end: 0x2008))
        super.init("PGR-ROM", range, mirror)
        self.memoryMap = memoryMap
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
