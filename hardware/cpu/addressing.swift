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

enum AddressingMode {
    case immediate
    case relative
    case implied, accumulator
    case zeroPage(Alteration)
    case absolute(Alteration)
    case indirect(Alteration)
    enum Alteration: UInt8 { case none = 0, x = 1, y = 2 }
}

protocol OperandBuilder {
    func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand
}

class EmptyOperandBuilder: OperandBuilder {
    func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand { return Operand() }
}

class AlteredOperandBuilder: OperandBuilder {   // Abstract
    let alteration: AddressingMode.Alteration
    init(_ alteration: AddressingMode.Alteration = .none) { self.alteration = alteration }
    func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand { return Operand() }
}

class ZeroPageAddressingOperandBuilder: AlteredOperandBuilder {
    override func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand {
        let alterationValue: Byte = self.alteration != .none ? (self.alteration == .x ? regs.x : regs.y) : 0
        var operand = Operand()
        operand.address = (memory.readByte(at: regs.pc).asWord() + alterationValue) & 0xFF
        operand.value = memory.readByte(at: operand.address).asWord()
        regs.pc++
        return operand
    }
}

class AbsoluteAddressingOperandBuilder: AlteredOperandBuilder {
    override func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand {
        let alterationValue: Byte = self.alteration != .none ? (self.alteration == .x ? regs.x : regs.y) : 0
        var operand = Operand()
        operand.address = memory.readWord(at: regs.pc) + alterationValue
        operand.value = memory.readByte(at: operand.address).asWord()
        regs.pc += 2
        operand.additionalCycles = self.alteration != .none ? UInt8(regs.isAtSamePage(than: operand.address)) : 0
        return operand
    }
}

class RelativeAddressingOperandBuilder: OperandBuilder {
    func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand {
        var operand = Operand()

        // transform the relative address into an absolute address
        let value = memory.readByte(at: regs.pc)
        regs.pc++
        operand.address = regs.pc
        if value.isSignBitOn() {
            operand.address -= Word(128 - value & 0b01111111)
        } else {
            operand.address += value.asWord() & 0b01111111
        }

        operand.additionalCycles = UInt8(regs.isAtSamePage(than: operand.address))
        return operand
    }
}

class ImmediateAddressingOperandBuilder: OperandBuilder {
    func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand {
        var operand = Operand()
        operand.value = memory.readByte(at: regs.pc).asWord()
        regs.pc++
        return operand
    }
}

class IndirectAddressingMode: AlteredOperandBuilder {
    override func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand {
        var addressPointer: Word = self.alteration == .x ? regs.x.asWord() : 0
        if self.alteration == .none {
            addressPointer &+= memory.readWord(at: regs.pc)
        } else {
            addressPointer &+= memory.readByte(at: regs.pc).asWord()
        }

        var operand = Operand()
        operand.address = memory.readWordGlitched(at: addressPointer) &+ (self.alteration == .y ? regs.y : 0)
        operand.value = memory.readByte(at: operand.address).asWord()

        regs.pc += self.alteration == .none ? 2 : 1
        operand.additionalCycles = self.alteration == .y ? UInt8(regs.isAtSamePage(than: operand.address)) : 0
        return operand
    }
}
