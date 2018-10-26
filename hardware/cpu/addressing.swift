//
//  Created by Alexandre Frigon on 2018-10-26.
//  Copyright © 2018 Frigstudio. All rights reserved.
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
        operand.address = (memory.readByte(at: regs.pc) + alterationValue).asWord()
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
        operand.address = memory.readByte(at: regs.pc).asWord()
        
        if Bool(operand.address & 0x80) {
            operand.address -= 0x100 + regs.pc
        }
        
        regs.pc++
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
        let addressPointer: Word = memory.readWord(at: regs.pc) &+ (self.alteration == .x ? regs.x : 0)
        
        var operand = Operand()
        operand.address = memory.readWordGlitched(at: addressPointer) &+ (self.alteration == .y ? regs.y : 0)
        operand.value = memory.readByte(at: operand.address).asWord()
        
        regs.pc += self.alteration == .none ? 2 : 1
        operand.additionalCycles = self.alteration == .y ? UInt8(regs.isAtSamePage(than: operand.address)) : 0
        return operand
    }
}
