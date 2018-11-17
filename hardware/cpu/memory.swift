//
//    MIT License
//
//    Copyright (c) 2018 Alexandre Frigon
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

class Stack: GuardStatus {
    private let bus: Bus
    private var sp: UnsafeMutablePointer<StackPointerRegister>
    let size: Word = 0x100

    var status: String {
        let size: UInt8 = 10
        let pointer: Word = self.sp.pointee.asWord() + self.size
        var stackString: String = ""

        for i in stride(from: pointer, to: pointer + size, by: 1) {
            if i >= 0x200 { break }
            stackString += " 0x\(Word(i).hex()): 0x\(self.bus.readByte(at: i).hex())\n"
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
        self.bus.writeByte(data, at: self.sp.pointee.asWord() + self.size)
        self.sp.pointee--
    }

    func popByte() -> Byte {
        self.sp.pointee++
        return self.bus.readByte(at: self.sp.pointee.asWord() + self.size)
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
