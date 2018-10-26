//
//  Created by Alexandre Frigon on 2018-10-26.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

class Stack: GuardStatus {
    private let bus: Bus
    private var sp: UnsafeMutablePointer<StackPointerRegister>
    let size: Word = 0x100
    
    var status: String {
        let size: UInt8 = 10
        let pointer: Word = self.sp.pointee.asWord() + 0x100
        var stackString: String = ""
        
        for i in stride(from: pointer, through: max(pointer - size - 1, 0x100), by: -2) {
            stackString += " 0x\(Word(i).hex()):  0x\(self.bus.readByte(at: i).hex()) 0x\(self.bus.readByte(at: i - 1).hex())\n"
        }
        
        return """
        |------- Stack -------|
        \(stackString)
        """
    }
    
    init(using bus: Bus, sp: UnsafeMutablePointer<StackPointerRegister>) {
        self.bus = bus
        self.sp = sp
    }
    
    func pushByte(data: Byte) {
        self.bus.writeByte(data, at: self.sp.pointee.asWord())
        self.sp.pointee--
    }

    func popByte() -> Byte {
        self.sp.pointee++
        return self.bus.readByte(at: self.sp.pointee.asWord())
    }

    func pushWord(data: Word) {
        self.pushByte(data: data.leftByte())
        self.pushByte(data: data.rightByte())
    }

    func popWord() -> Word {
        return self.popByte().asWord() + self.popByte().asWord() << 8
    }
}

class CoreProcessingUnitMemory {
    private let bus: Bus
    
    init(using bus: Bus) {
        self.bus = bus
    }
    
    func readByte(at address: Word) -> Byte {
        return self.bus.readByte(at: address)
    }

    func writeByte(_ data: Byte, at address: Word) {
        self.bus.writeByte(data, at: address)
    }

    func readWord(at address: Word) -> Word {
        return self.readByte(at: address).asWord() + self.readByte(at: address + 1).asWord() << 8
    }

    func writeWord(_ data: Word, at address: Word) {
        self.writeByte(data.rightByte(), at: address)
        self.writeByte(data.leftByte(), at: address + 1)
    }
    
    func readWordGlitched(at address: Word) -> Word {
        // 6502 hardware bug, instead of reading from 0xC0FF/0xC100 it reads from 0xC0FF/0xC000
        if address.rightByte() == 0xFF {
            return self.readByte(at: address & 0xFF00).asWord() << 8 + self.readByte(at: address)
        }
        return self.readWord(at: address)
    }
}
