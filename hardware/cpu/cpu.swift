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

typealias AccumulatorRegister = Byte
typealias XIndexRegister = Byte
typealias YIndexRegister = Byte
typealias StackPointerRegister = Byte
typealias ProgramCounterRegister = Word

class ProcessorStatusRegister {
    private var _value: Byte
    var value: Byte { return self._value }

    init(_ value: Byte) { self._value = value }
    static func &= (left: inout ProcessorStatusRegister, right: Byte) { left._value = right }
    static func == (left: ProcessorStatusRegister, right: ProcessorStatusRegister) -> Bool {
        return left.value == right.value
    }
    static func != (left: ProcessorStatusRegister, right: ProcessorStatusRegister) -> Bool {
        return left.value != right.value
    }

    func set(_ flags: Byte, if condition: Bool? = nil) {
        if let condition = condition {
            return condition ? self.set(flags) : self.unset(flags)
        }

        self._value |= flags
    }

    func set(_ flag: Flag, if condition: Bool? = nil) { self.set(flag.rawValue, if: condition) }
    func unset(_ flags: Byte) { self._value &= ~flags }
    func unset(_ flag: Flag) { self.unset(flag.rawValue) }
    func isSet(_ flag: Flag) -> Bool { return Bool(self.value & flag.rawValue) }
    func isNotSet(_ flag: Flag) -> Bool { return !self.isSet(flag) }
    func valueOf(_ flag: Flag) -> UInt8 { return self.isSet(flag) ? 1 : 0 }

    func updateFor(_ value: Word) { self.updateFor(value.rightByte()) }
    func updateFor(_ value: Byte) {
        self.set(.zero, if: value.isZero())
        self.set(.negative, if: value.isSignBitOn())
    }
}

enum Flag: UInt8 {
    case carry      = 1     // 0b00000001   C
    case zero       = 2     // 0b00000010   Z
    case interrupt  = 4     // 0b00000100   I
    case decimal    = 8     // 0b00001000   D
    case breaks     = 16    // 0b00010000   B
    case alwaysOne  = 32    // 0b00100000
    case overflow   = 64    // 0b01000000   V
    case negative   = 128   // 0b10000000   N

    static func | (left: Flag, right: Flag) -> UInt8 { return left.rawValue | right.rawValue }
    static func & (left: Flag, right: Flag) -> UInt8 { return left.rawValue & right.rawValue }
    static prefix func ~ (value: Flag) -> UInt8 { return ~value.rawValue }
}

struct RegisterSet {
    var a: AccumulatorRegister      = 0x00
    var x: XIndexRegister           = 0x00
    var y: YIndexRegister           = 0x00
    var p: ProcessorStatusRegister  = ProcessorStatusRegister(Flag.alwaysOne | Flag.breaks)
    var sp: StackPointerRegister    = 0xFD
    var pc: ProgramCounterRegister  = 0x0000

    func isAtSamePage(than address: Word) -> Bool {
        return self.pc >> 8 != address >> 8
    }
}

struct Opcode {
    let closure: (Word, Word) -> Void
    let cycles: UInt8
    let addressingMode: AddressingMode

    init(_ closure: @escaping (Word, Word) -> Void, _ cycles: UInt8, _ addressingMode: AddressingMode) {
        self.closure = closure
        self.cycles = cycles
        self.addressingMode = addressingMode
    }
}

struct Operand {
    var value: Word
    var address: Word
    var additionalCycles: UInt8

    init(value: Word = 0x0000, address: Word = 0x0000, additionalCycles: UInt8 = 0) {
        self.value = value
        self.address = address
        self.additionalCycles = additionalCycles
    }
}

enum InterruptType: Word {
    case nmi = 0xFFFA       // Non-Maskable Interrupt triggered by ppu
    case reset = 0xFFFC     // Triggered on reset button press and initial boot
    case irq = 0xFFFE       // Maskable Interrupt triggered by a brk instruction or by memory mappers
    var address: Word { return self.rawValue }
}

class CoreProcessingUnit {
    let frequency: Double = 1.789773    // MHz
    private let memory: CoreProcessingUnitMemory
    private let stack: Stack
    private let bus: Bus
    private var regs: RegisterSet
    private var opcodes: [Byte: Opcode]! = nil
    private var interruptRequest: InterruptType?

    var registers: RegisterSet { return self.regs }

    var status: String {
        return """
        |-------- CPU --------|
         a:  0x\(self.regs.a.hex())   sp: 0x\(self.regs.sp.hex())
         x:  0x\(self.regs.x.hex())    y: 0x\(self.regs.y.hex())
         pc: 0x\(self.regs.pc.hex())
         p:  0b\(self.regs.p.value.bin())
               NV-BDIZC

        \(self.stack.status)
        """
    }

    init(using bus: Bus, with registers: RegisterSet = RegisterSet()) {
        self.bus = bus
        self.regs = registers
        self.memory = CoreProcessingUnitMemory(using: bus)
        self.stack = Stack(using: self.bus, sp: &self.regs.sp)

        self.opcodes = [
            0x00: Opcode(brk, 7, .implied),
            0x01: Opcode(ora, 6, .indirect(.x)),
            0x05: Opcode(ora, 3, .zeroPage(.none)),
            0x06: Opcode(asl, 5, .zeroPage(.none)),
            0x08: Opcode(php, 3, .implied),
            0x09: Opcode(ora, 2, .immediate),
            0x0A: Opcode(asla, 2, .accumulator),
            0x0D: Opcode(ora, 4, .absolute(.none)),
            0x0E: Opcode(asl, 6, .absolute(.none)),
            0x10: Opcode(bpl, 2, .relative),
            0x11: Opcode(ora, 5, .indirect(.y)),
            0x15: Opcode(ora, 4, .zeroPage(.x)),
            0x16: Opcode(asl, 6, .zeroPage(.x)),
            0x18: Opcode(clc, 2, .implied),
            0x19: Opcode(ora, 4, .absolute(.y)),
            0x1D: Opcode(ora, 4, .absolute(.x)),
            0x1E: Opcode(asl, 7, .absolute(.x)),
            0x20: Opcode(jsr, 6, .absolute(.none)),
            0x21: Opcode(and, 6, .indirect(.x)),
            0x24: Opcode(bit, 3, .zeroPage(.none)),
            0x25: Opcode(and, 3, .zeroPage(.none)),
            0x26: Opcode(rol, 5, .zeroPage(.none)),
            0x28: Opcode(plp, 4, .implied),
            0x29: Opcode(and, 2, .immediate),
            0x2A: Opcode(rola, 2, .accumulator),
            0x2C: Opcode(bit, 4, .absolute(.none)),
            0x2D: Opcode(and, 2, .absolute(.none)),
            0x2E: Opcode(rol, 6, .absolute(.none)),
            0x30: Opcode(bmi, 2, .relative),
            0x31: Opcode(and, 5, .indirect(.y)),
            0x35: Opcode(and, 4, .zeroPage(.x)),
            0x36: Opcode(rol, 6, .zeroPage(.x)),
            0x38: Opcode(sec, 2, .implied),
            0x39: Opcode(and, 4, .absolute(.y)),
            0x3D: Opcode(and, 4, .absolute(.x)),
            0x3E: Opcode(rol, 7, .absolute(.x)),
            0x40: Opcode(rti, 6, .implied),
            0x41: Opcode(eor, 6, .indirect(.x)),
            0x45: Opcode(eor, 3, .zeroPage(.none)),
            0x46: Opcode(lsr, 5, .zeroPage(.none)),
            0x48: Opcode(pha, 3, .implied),
            0x49: Opcode(eor, 2, .immediate),
            0x4A: Opcode(lsra, 2, .accumulator),
            0x4C: Opcode(jmp, 3, .absolute(.none)),
            0x4D: Opcode(eor, 4, .absolute(.none)),
            0x4E: Opcode(lsr, 6, .absolute(.none)),
            0x50: Opcode(bvc, 2, .relative),
            0x51: Opcode(eor, 5, .indirect(.y)),
            0x55: Opcode(eor, 4, .zeroPage(.x)),
            0x56: Opcode(lsr, 6, .zeroPage(.x)),
            0x58: Opcode(cli, 2, .implied),
            0x59: Opcode(eor, 4, .absolute(.y)),
            0x5D: Opcode(eor, 4, .absolute(.x)),
            0x5E: Opcode(lsr, 7, .absolute(.x)),
            0x60: Opcode(rts, 6, .implied),
            0x61: Opcode(adc, 6, .indirect(.x)),
            0x65: Opcode(adc, 3, .zeroPage(.none)),
            0x66: Opcode(ror, 5, .zeroPage(.none)),
            0x68: Opcode(pla, 4, .implied),
            0x69: Opcode(adc, 2, .immediate),
            0x6A: Opcode(rora, 2, .accumulator),
            0x6C: Opcode(jmp, 5, .indirect(.none)),
            0x6D: Opcode(adc, 4, .absolute(.none)),
            0x6E: Opcode(ror, 6, .absolute(.none)),
            0x70: Opcode(bvs, 2, .relative),
            0x71: Opcode(adc, 5, .indirect(.y)),
            0x75: Opcode(adc, 4, .zeroPage(.x)),
            0x76: Opcode(ror, 6, .zeroPage(.x)),
            0x78: Opcode(sei, 2, .implied),
            0x79: Opcode(adc, 4, .absolute(.y)),
            0x7D: Opcode(adc, 4, .absolute(.x)),
            0x7E: Opcode(ror, 7, .absolute(.x)),
            0x81: Opcode(sta, 6, .indirect(.x)),
            0x84: Opcode(sty, 3, .zeroPage(.none)),
            0x85: Opcode(sta, 3, .zeroPage(.none)),
            0x86: Opcode(stx, 3, .zeroPage(.none)),
            0x88: Opcode(dey, 2, .implied),
            0x8A: Opcode(txa, 2, .implied),
            0x8C: Opcode(sty, 4, .absolute(.none)),
            0x8D: Opcode(sta, 4, .absolute(.none)),
            0x8E: Opcode(stx, 4, .absolute(.none)),
            0x90: Opcode(bcc, 2, .relative),
            0x91: Opcode(sta, 6, .indirect(.y)),
            0x94: Opcode(sty, 4, .zeroPage(.x)),
            0x95: Opcode(sta, 4, .zeroPage(.x)),
            0x96: Opcode(stx, 4, .zeroPage(.y)),
            0x98: Opcode(tya, 2, .implied),
            0x99: Opcode(sta, 5, .absolute(.y)),
            0x9A: Opcode(txs, 2, .implied),
            0x9D: Opcode(sta, 5, .absolute(.x)),
            0xA0: Opcode(ldy, 2, .immediate),
            0xA1: Opcode(lda, 6, .indirect(.x)),
            0xA2: Opcode(ldx, 2, .immediate),
            0xA4: Opcode(ldy, 3, .zeroPage(.none)),
            0xA5: Opcode(lda, 3, .zeroPage(.none)),
            0xA6: Opcode(ldx, 3, .zeroPage(.none)),
            0xA8: Opcode(tay, 2, .implied),
            0xA9: Opcode(lda, 2, .immediate),
            0xAA: Opcode(tax, 2, .implied),
            0xAC: Opcode(ldy, 4, .absolute(.none)),
            0xAD: Opcode(lda, 4, .absolute(.none)),
            0xAE: Opcode(ldx, 4, .absolute(.none)),
            0xB0: Opcode(bcs, 2, .relative),
            0xB1: Opcode(lda, 5, .indirect(.y)),
            0xB4: Opcode(ldy, 4, .zeroPage(.x)),
            0xB5: Opcode(lda, 4, .zeroPage(.x)),
            0xB6: Opcode(ldx, 4, .zeroPage(.y)),
            0xB8: Opcode(clv, 2, .implied),
            0xB9: Opcode(lda, 4, .absolute(.y)),
            0xBA: Opcode(tsx, 2, .implied),
            0xBC: Opcode(ldy, 4, .absolute(.x)),
            0xBD: Opcode(lda, 4, .absolute(.x)),
            0xBE: Opcode(ldx, 4, .absolute(.y)),
            0xC0: Opcode(cpy, 2, .immediate),
            0xC1: Opcode(cmp, 6, .indirect(.x)),
            0xC4: Opcode(cpy, 3, .zeroPage(.none)),
            0xC5: Opcode(cmp, 3, .zeroPage(.none)),
            0xC6: Opcode(dec, 5, .zeroPage(.none)),
            0xC8: Opcode(iny, 2, .implied),
            0xC9: Opcode(cmp, 2, .immediate),
            0xCA: Opcode(dex, 2, .implied),
            0xCC: Opcode(cpy, 4, .absolute(.none)),
            0xCD: Opcode(cmp, 4, .absolute(.none)),
            0xCE: Opcode(dec, 6, .absolute(.none)),
            0xD0: Opcode(bne, 2, .relative),
            0xD1: Opcode(cmp, 5, .indirect(.y)),
            0xD5: Opcode(cmp, 4, .zeroPage(.x)),
            0xD6: Opcode(dec, 6, .zeroPage(.x)),
            0xD8: Opcode(cld, 2, .implied),
            0xD9: Opcode(cmp, 4, .absolute(.y)),
            0xDD: Opcode(cmp, 4, .absolute(.x)),
            0xDE: Opcode(dec, 7, .absolute(.x)),
            0xE0: Opcode(cpx, 2, .immediate),
            0xE1: Opcode(sbc, 6, .indirect(.x)),
            0xE4: Opcode(cpx, 3, .zeroPage(.none)),
            0xE5: Opcode(sbc, 3, .zeroPage(.none)),
            0xE6: Opcode(inc, 5, .zeroPage(.none)),
            0xE8: Opcode(inx, 2, .implied),
            0xE9: Opcode(sbc, 2, .immediate),
            0xEA: Opcode(nop, 2, .implied),
            0xEC: Opcode(cpx, 4, .absolute(.none)),
            0xED: Opcode(sbc, 4, .absolute(.none)),
            0xEE: Opcode(inc, 6, .absolute(.none)),
            0xF0: Opcode(beq, 2, .relative),
            0xF1: Opcode(sbc, 5, .indirect(.y)),
            0xF5: Opcode(sbc, 4, .zeroPage(.x)),
            0xF6: Opcode(inc, 6, .zeroPage(.x)),
            0xF8: Opcode(sed, 2, .implied),
            0xF9: Opcode(sbc, 4, .absolute(.y)),
            0xFD: Opcode(sbc, 4, .absolute(.x)),
            0xFE: Opcode(inc, 7, .absolute(.x))
        ]
    }

    func requestInterrupt(type: InterruptType) {
        // maybe handle interrupt priority as described in this document at page 13
        // http://nesdev.com/NESDoc.pdf
        self.interruptRequest = type

        // maybe will have to switch to a queue of interrupts ?
    }

    /// Method used to inject instructions for testing
    func process(opcode: Byte, operand: Operand = Operand()) {
        guard let opcode: Opcode = self.opcodes[opcode] else {
            fatalError("Unknown opcode used (outside of the 151 available)")
        }

        opcode.closure(operand.value, operand.address)
    }

    @discardableResult
    func step() -> UInt8 {
        if let interrupt = self.interruptRequest {
            return self.interrupt(type: interrupt)
        }

        let opcodeHex: Byte = self.memory.readByte(at: regs.pc)
        regs.pc++

        guard let opcode: Opcode = self.opcodes[opcodeHex] else {
            fatalError("Unknown opcode used (outside of the 151 available)")
        }

        let operand: Operand = self.buildOperand(using: opcode.addressingMode)
        opcode.closure(operand.value, operand.address)

        return opcode.cycles + operand.additionalCycles
    }

    @discardableResult
    private func interrupt(type: InterruptType) -> UInt8 {
        self.interruptRequest = nil

        // Handle the bit 7 of PPU Control Register 1 ($2000)
        let isValidNmi: Bool = type == .nmi && Bool(self.memory.readByte(at: 0x2000) & 0b10000000)

        guard type == .irq || isValidNmi || self.regs.p.isNotSet(.interrupt) else {
            return 0
        }

        if type == .reset { self.regs.sp = 0xFD }

        stack.pushWord(data: regs.pc + 1)
        stack.pushByte(data: regs.p.value | Flag.alwaysOne.rawValue)
        self.regs.p.set(.interrupt)
        self.regs.pc = memory.readWord(at: type.address)

        return 7
    }

    private func buildOperand(using addressingMode: AddressingMode) -> Operand {
        switch addressingMode {
        case .zeroPage(let alteration): return ZeroPageAddressingOperandBuilder(alteration).evaluate(&regs, memory)
        case .absolute(let alteration): return AbsoluteAddressingOperandBuilder(alteration).evaluate(&regs, memory)
        case .relative: return RelativeAddressingOperandBuilder().evaluate(&regs, memory)
        case .indirect(let alteration): return IndirectAddressingMode(alteration).evaluate(&regs, memory)
        case .immediate: return ImmediateAddressingOperandBuilder().evaluate(&regs, memory)
        case .implied, .accumulator: fallthrough
        default: return EmptyOperandBuilder().evaluate(&regs, memory)
        }
    }

    // OPCODES IMPLEMENTATION
    private func nop(_ value: Word, _ address: Word) {}

    // Math
    private func inx(_ value: Word, _ address: Word) { regs.x++; regs.p.updateFor(regs.x) }
    private func iny(_ value: Word, _ address: Word) { regs.y++; regs.p.updateFor(regs.y) }
    private func dex(_ value: Word, _ address: Word) { regs.x--; regs.p.updateFor(regs.x) }
    private func dey(_ value: Word, _ address: Word) { regs.y--; regs.p.updateFor(regs.y) }

    private func adc(_ value: Word, _ address: Word) {
        let result = regs.a &+ value &+ regs.p.valueOf(.carry)
        regs.p.set(.carry, if: result.overflowsByte())
        regs.p.set(.overflow, if: Bool(~(regs.a ^ value) & (regs.a ^ result) & Flag.negative.rawValue))
        regs.a = result.rightByte()
        regs.p.updateFor(regs.a)
    }

    private func sbc(_ value: Word, _ address: Word) {
        let result = regs.a &- value &- (1 - regs.p.valueOf(.carry))
        regs.p.set(.carry, if: !result.overflowsByte())
        regs.p.set(.overflow, if: Bool((regs.a ^ value) & (regs.a ^ result) & Flag.negative.rawValue))
        regs.a = result.rightByte()
        regs.p.updateFor(regs.a)
    }

    private func inc(_ value: Word, _ address: Word) {
        let result: Byte = value.rightByte() &+ 1
        memory.writeByte(result, at: address)
        regs.p.updateFor(result)
    }

    private func dec(_ value: Word, _ address: Word) {
        let result: Byte = value.rightByte() &- 1
        memory.writeByte(result, at: address)
        regs.p.updateFor(result)
    }

    // Bitwise
    private func and(_ value: Word, _ address: Word) { regs.a &= value; regs.p.updateFor(regs.a) }
    private func eor(_ value: Word, _ address: Word) { regs.a ^= value; regs.p.updateFor(regs.a) }
    private func ora(_ value: Word, _ address: Word) { regs.a |= value; regs.p.updateFor(regs.a) }

    private func bit(_ value: Word, _ address: Word) {
        regs.p.set(.zero, if: Bool(regs.a & value))
        regs.p.set((.overflow | .negative) & value)
    }

    private func asl(_ value: Word, _ address: Word) {
        regs.p.set(.carry, if: value.rightByte().isMostSignificantBitOn())
        let result: Byte = value.rightByte() << 1
        regs.p.updateFor(result)
        memory.writeByte(result, at: address)
    }

    private func lsr(_ value: Word, _ address: Word) {
        regs.p.set(.carry, if: value.rightByte().isLeastSignificantBitOn())
        let result: Byte = value.rightByte() >> 1
        regs.p.updateFor(result)
        memory.writeByte(result, at: address)
    }

    private func rol(_ value: Word, _ address: Word) {
        let result: Word = value << 1 | regs.p.valueOf(.carry)
        regs.p.set(.carry, if: result.overflowsByteByOne())
        memory.writeByte(result.rightByte(), at: address)
        regs.p.updateFor(result)
    }

    private func ror(_ value: Word, _ address: Word) {
        let carry: Byte = regs.p.valueOf(.carry)
        regs.p.set(.carry, if: value.isLeastSignificantBitOn())
        let result: Byte = value.rightByte() >> 1 | carry << 7
        regs.p.updateFor(result)
        memory.writeByte(result, at: address)
    }

    private func asla(_ value: Word, _ address: Word) {
        regs.p.set(.carry, if: regs.a.isMostSignificantBitOn())
        regs.a <<= 1
        regs.p.updateFor(regs.a)
    }

    private func lsra(_ value: Word, _ address: Word) {
        regs.p.set(.carry, if: regs.a.isLeastSignificantBitOn())
        regs.a >>= 1
        regs.p.updateFor(regs.a)
    }

    private func rola(_ value: Word, _ address: Word) {
        let result: Word = regs.a.asWord() << 1 | regs.p.valueOf(.carry)
        regs.p.set(.carry, if: result.overflowsByteByOne())
        regs.a = result.rightByte()
        regs.p.updateFor(regs.a)
    }

    private func rora(_ value: Word, _ address: Word) {
        let carry = regs.p.valueOf(.carry)
        regs.p.set(.carry, if: regs.a.isLeastSignificantBitOn())
        regs.a = regs.a >> 1 | carry << 7
        regs.p.updateFor(regs.a)
    }

    // flags
    private func clc(_ value: Word, _ address: Word) { regs.p.unset(.carry) }
    private func cld(_ value: Word, _ address: Word) { regs.p.unset(.decimal) }
    private func cli(_ value: Word, _ address: Word) { regs.p.unset(.interrupt) }
    private func clv(_ value: Word, _ address: Word) { regs.p.unset(.overflow) }
    private func sec(_ value: Word, _ address: Word) { regs.p.set(.carry) }
    private func sed(_ value: Word, _ address: Word) { regs.p.set(.decimal) }
    private func sei(_ value: Word, _ address: Word) { regs.p.set(.interrupt) }

    // comparison
    private func compare(_ a: Byte, _ value: Word) {
        regs.p.updateFor(a &- value.rightByte())
        regs.p.set(.carry, if: regs.a >= value)
    }
    private func cmp(_ value: Word, _ address: Word) { compare(regs.a, value) }
    private func cpx(_ value: Word, _ address: Word) { compare(regs.x, value) }
    private func cpy(_ value: Word, _ address: Word) { compare(regs.y, value) }

    // branches
    private func branch(to address: Word, if condition: Bool) { if condition { regs.pc = address } } // additionalCycles += 1 on success ?
    private func beq(_ value: Word, _ address: Word) { branch(to: address, if: regs.p.isSet(.zero)) }
    private func bne(_ value: Word, _ address: Word) { branch(to: address, if: !regs.p.isSet(.zero)) }
    private func bmi(_ value: Word, _ address: Word) { branch(to: address, if: regs.p.isSet(.negative)) }
    private func bpl(_ value: Word, _ address: Word) { branch(to: address, if: !regs.p.isSet(.negative)) }
    private func bcs(_ value: Word, _ address: Word) { branch(to: address, if: regs.p.isSet(.carry)) }
    private func bcc(_ value: Word, _ address: Word) { branch(to: address, if: !regs.p.isSet(.carry)) }
    private func bvs(_ value: Word, _ address: Word) { branch(to: address, if: regs.p.isSet(.overflow)) }
    private func bvc(_ value: Word, _ address: Word) { branch(to: address, if: !regs.p.isSet(.overflow)) }

    // jump
    private func jmp(_ value: Word, _ address: Word) { regs.pc = address }

    // subroutines
    private func jsr(_ value: Word, _ address: Word) { stack.pushWord(data: regs.pc &- 1); regs.pc = address }
    private func rts(_ value: Word, _ address: Word) { regs.pc = stack.popWord() &+ 1 }

    // interruptions
    private func rti(_ value: Word, _ address: Word) {
        regs.p &= stack.popByte() | Flag.alwaysOne.rawValue
        regs.pc = stack.popWord()
    }

    private func brk(_ value: Word, _ address: Word) {
        self.regs.p.set(.breaks)
        self.interrupt(type: .irq)
    }

    // stack
    private func pha(_ value: Word, _ address: Word) { stack.pushByte(data: regs.a) }
    private func php(_ value: Word, _ address: Word) { stack.pushByte(data: regs.p.value | (.alwaysOne | .breaks)) }
    private func pla(_ value: Word, _ address: Word) { regs.a = stack.popByte(); regs.p.updateFor(regs.a) }
    private func plp(_ value: Word, _ address: Word) { regs.p &= stack.popByte() & ~Flag.breaks.rawValue | Flag.alwaysOne.rawValue }

    // loading
    private func load(_ a: inout Byte, _ operand: Word) { a = operand.rightByte(); regs.p.updateFor(a) }
    private func lda(_ value: Word, _ address: Word) { self.load(&regs.a, value) }
    private func ldx(_ value: Word, _ address: Word) { self.load(&regs.x, value) }
    private func ldy(_ value: Word, _ address: Word) { self.load(&regs.y, value) }

    // storing
    private func sta(_ value: Word, _ address: Word) { memory.writeByte(regs.a, at: address) }
    private func stx(_ value: Word, _ address: Word) { memory.writeByte(regs.x, at: address) }
    private func sty(_ value: Word, _ address: Word) { memory.writeByte(regs.y, at: address) }

    // transfering
    private func transfer(_ a: inout Byte, _ b: Byte) { a = b; regs.p.updateFor(a) }
    private func tax(_ value: Word, _ address: Word) { self.transfer(&regs.x, regs.a) }
    private func txa(_ value: Word, _ address: Word) { self.transfer(&regs.a, regs.x) }
    private func tay(_ value: Word, _ address: Word) { self.transfer(&regs.y, regs.a) }
    private func tya(_ value: Word, _ address: Word) { self.transfer(&regs.a, regs.y) }
    private func tsx(_ value: Word, _ address: Word) { self.transfer(&regs.x, regs.sp) }
    private func txs(_ value: Word, _ address: Word) { regs.sp = regs.x }
}
