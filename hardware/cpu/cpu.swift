//
//    MIT License
//
//    Copyright (c) 2019 Alexandre Frigon
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

    func set(flags: Byte, if condition: Bool? = nil) {
        if let condition = condition {
            return condition ? self.set(flags: flags) : self.unset(flags)
        }

        self._value |= flags
    }

    func set(_ flag: Flag, if condition: Bool? = nil) { self.set(flags: flag.rawValue, if: condition) }
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
}

enum InterruptType: Word {
    case nmi = 0xFFFA       // Non-Maskable Interrupt triggered by ppu
    case reset = 0xFFFC     // Triggered on reset button press and initial boot
    case irq = 0xFFFE       // Maskable Interrupt triggered by a brk instruction or by memory mappers
    var address: Word { return self.rawValue }
}

struct Opcode {
    let closure: (inout Operand) -> Void
    let name: String
    let cycles: UInt8
    let addressingMode: AddressingMode

    init(_ closure: @escaping (inout Operand) -> Void, _ name: String, _ cycles: UInt8, _ addressingMode: AddressingMode) {
        self.closure = closure
        self.name = name
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

class CoreProcessingUnit {
    private weak var bus: Bus!
    private let memory: CoreProcessingUnitMemory
    private let stack: Stack
    private var regs: RegisterSet
    private var opcodes: [Byte: Opcode]! = nil
    private var interruptRequest: InterruptType?
    var registers: RegisterSet { return self.regs }
    let frequency: Double = 1789773
    var stallCycles: UInt16 = 0
    var totalCycles: UInt64 = 0

    func opcodeInfo(for opcode: Byte) -> (String, AddressingMode) {
        return (self.opcodes[opcode]?.name ?? "undefined", self.opcodes[opcode]?.addressingMode ?? .implied)
    }

    init(using bus: Bus, with registers: RegisterSet = RegisterSet()) {
        self.bus = bus
        self.regs = registers
        self.memory = CoreProcessingUnitMemory(using: bus)
        self.stack = Stack(using: self.bus, sp: &self.regs.sp)

        self.opcodes = [
            0x00: Opcode(brk, "brk", 7, .implied),
            0x01: Opcode(ora, "ora", 6, .indirect(.x)),
            0x05: Opcode(ora, "ora", 3, .zeroPage(.none)),
            0x06: Opcode(asl, "asl", 5, .zeroPage(.none)),
            0x08: Opcode(php, "php", 3, .implied),
            0x09: Opcode(ora, "ora", 2, .immediate),
            0x0A: Opcode(asla, "asl", 2, .accumulator),
            0x0D: Opcode(ora, "ora", 4, .absolute(.none, true)),
            0x0E: Opcode(asl, "asl", 6, .absolute(.none, true)),
            0x10: Opcode(bpl, "bpl", 2, .relative),
            0x11: Opcode(ora, "ora", 5, .indirect(.y)),
            0x15: Opcode(ora, "ora", 4, .zeroPage(.x)),
            0x16: Opcode(asl, "asl", 6, .zeroPage(.x)),
            0x18: Opcode(clc, "clc", 2, .implied),
            0x19: Opcode(ora, "ora", 4, .absolute(.y, true)),
            0x1D: Opcode(ora, "ora", 4, .absolute(.x, true)),
            0x1E: Opcode(asl, "asl", 7, .absolute(.x, true)),
            0x20: Opcode(jsr, "jsr", 6, .absolute(.none, false)),
            0x21: Opcode(and, "and", 6, .indirect(.x)),
            0x24: Opcode(bit, "bit", 3, .zeroPage(.none)),
            0x25: Opcode(and, "and", 3, .zeroPage(.none)),
            0x26: Opcode(rol, "rol", 5, .zeroPage(.none)),
            0x28: Opcode(plp, "plp", 4, .implied),
            0x29: Opcode(and, "and", 2, .immediate),
            0x2A: Opcode(rola, "rol", 2, .accumulator),
            0x2C: Opcode(bit, "bit", 4, .absolute(.none, true)),
            0x2D: Opcode(and, "and", 2, .absolute(.none, true)),
            0x2E: Opcode(rol, "rol", 6, .absolute(.none, true)),
            0x30: Opcode(bmi, "bmi", 2, .relative),
            0x31: Opcode(and, "and", 5, .indirect(.y)),
            0x35: Opcode(and, "and", 4, .zeroPage(.x)),
            0x36: Opcode(rol, "rol", 6, .zeroPage(.x)),
            0x38: Opcode(sec, "sec", 2, .implied),
            0x39: Opcode(and, "and", 4, .absolute(.y, true)),
            0x3D: Opcode(and, "and", 4, .absolute(.x, true)),
            0x3E: Opcode(rol, "rol", 7, .absolute(.x, true)),
            0x40: Opcode(rti, "rti", 6, .implied),
            0x41: Opcode(eor, "eor", 6, .indirect(.x)),
            0x45: Opcode(eor, "eor", 3, .zeroPage(.none)),
            0x46: Opcode(lsr, "lsr", 5, .zeroPage(.none)),
            0x48: Opcode(pha, "pha", 3, .implied),
            0x49: Opcode(eor, "eor", 2, .immediate),
            0x4A: Opcode(lsra, "lsr", 2, .accumulator),
            0x4C: Opcode(jmp, "jmp", 3, .absolute(.none, false)),
            0x4D: Opcode(eor, "eor", 4, .absolute(.none, true)),
            0x4E: Opcode(lsr, "lsr", 6, .absolute(.none, true)),
            0x50: Opcode(bvc, "bvc", 2, .relative),
            0x51: Opcode(eor, "eor", 5, .indirect(.y)),
            0x55: Opcode(eor, "eor", 4, .zeroPage(.x)),
            0x56: Opcode(lsr, "lsr", 6, .zeroPage(.x)),
            0x58: Opcode(cli, "cli", 2, .implied),
            0x59: Opcode(eor, "eor", 4, .absolute(.y, true)),
            0x5D: Opcode(eor, "eor", 4, .absolute(.x, true)),
            0x5E: Opcode(lsr, "lsr", 7, .absolute(.x, true)),
            0x60: Opcode(rts, "rts", 6, .implied),
            0x61: Opcode(adc, "adc", 6, .indirect(.x)),
            0x65: Opcode(adc, "adc", 3, .zeroPage(.none)),
            0x66: Opcode(ror, "ror", 5, .zeroPage(.none)),
            0x68: Opcode(pla, "pla", 4, .implied),
            0x69: Opcode(adc, "adc", 2, .immediate),
            0x6A: Opcode(rora, "ror", 2, .accumulator),
            0x6C: Opcode(jmp, "jmp", 5, .indirect(.none)),
            0x6D: Opcode(adc, "adc", 4, .absolute(.none, true)),
            0x6E: Opcode(ror, "ror", 6, .absolute(.none, true)),
            0x70: Opcode(bvs, "bvs", 2, .relative),
            0x71: Opcode(adc, "adc", 5, .indirect(.y)),
            0x75: Opcode(adc, "adc", 4, .zeroPage(.x)),
            0x76: Opcode(ror, "ror", 6, .zeroPage(.x)),
            0x78: Opcode(sei, "sei", 2, .implied),
            0x79: Opcode(adc, "adc", 4, .absolute(.y, true)),
            0x7D: Opcode(adc, "adc", 4, .absolute(.x, true)),
            0x7E: Opcode(ror, "ror", 7, .absolute(.x, true)),
            0x81: Opcode(sta, "sta", 6, .indirect(.x)),
            0x84: Opcode(sty, "sty", 3, .zeroPage(.none)),
            0x85: Opcode(sta, "sta", 3, .zeroPage(.none)),
            0x86: Opcode(stx, "stx", 3, .zeroPage(.none)),
            0x88: Opcode(dey, "dey", 2, .implied),
            0x8A: Opcode(txa, "txa", 2, .implied),
            0x8C: Opcode(sty, "sty", 4, .absolute(.none, false)),
            0x8D: Opcode(sta, "sta", 4, .absolute(.none, false)),
            0x8E: Opcode(stx, "stx", 4, .absolute(.none, false)),
            0x90: Opcode(bcc, "bcc", 2, .relative),
            0x91: Opcode(sta, "sta", 6, .indirect(.y)),
            0x94: Opcode(sty, "sty", 4, .zeroPage(.x)),
            0x95: Opcode(sta, "sta", 4, .zeroPage(.x)),
            0x96: Opcode(stx, "stx", 4, .zeroPage(.y)),
            0x98: Opcode(tya, "tya", 2, .implied),
            0x99: Opcode(sta, "sta", 5, .absolute(.y, false)),
            0x9A: Opcode(txs, "txs", 2, .implied),
            0x9D: Opcode(sta, "sta", 5, .absolute(.x, false)),
            0xA0: Opcode(ldy, "ldy", 2, .immediate),
            0xA1: Opcode(lda, "lda", 6, .indirect(.x)),
            0xA2: Opcode(ldx, "ldx", 2, .immediate),
            0xA4: Opcode(ldy, "ldy", 3, .zeroPage(.none)),
            0xA5: Opcode(lda, "lda", 3, .zeroPage(.none)),
            0xA6: Opcode(ldx, "ldx", 3, .zeroPage(.none)),
            0xA8: Opcode(tay, "tay", 2, .implied),
            0xA9: Opcode(lda, "lda", 2, .immediate),
            0xAA: Opcode(tax, "tax", 2, .implied),
            0xAC: Opcode(ldy, "ldy", 4, .absolute(.none, true)),
            0xAD: Opcode(lda, "lda", 4, .absolute(.none, true)),
            0xAE: Opcode(ldx, "ldx", 4, .absolute(.none, true)),
            0xB0: Opcode(bcs, "bcs", 2, .relative),
            0xB1: Opcode(lda, "lda", 5, .indirect(.y)),
            0xB4: Opcode(ldy, "ldy", 4, .zeroPage(.x)),
            0xB5: Opcode(lda, "lda", 4, .zeroPage(.x)),
            0xB6: Opcode(ldx, "ldx", 4, .zeroPage(.y)),
            0xB8: Opcode(clv, "clv", 2, .implied),
            0xB9: Opcode(lda, "lda", 4, .absolute(.y, true)),
            0xBA: Opcode(tsx, "tsx", 2, .implied),
            0xBC: Opcode(ldy, "ldy", 4, .absolute(.x, true)),
            0xBD: Opcode(lda, "lda", 4, .absolute(.x, true)),
            0xBE: Opcode(ldx, "ldx", 4, .absolute(.y, true)),
            0xC0: Opcode(cpy, "cpy", 2, .immediate),
            0xC1: Opcode(cmp, "cmp", 6, .indirect(.x)),
            0xC4: Opcode(cpy, "cpy", 3, .zeroPage(.none)),
            0xC5: Opcode(cmp, "cmp", 3, .zeroPage(.none)),
            0xC6: Opcode(dec, "dec", 5, .zeroPage(.none)),
            0xC8: Opcode(iny, "iny", 2, .implied),
            0xC9: Opcode(cmp, "cmp", 2, .immediate),
            0xCA: Opcode(dex, "dex", 2, .implied),
            0xCC: Opcode(cpy, "cpy", 4, .absolute(.none, true)),
            0xCD: Opcode(cmp, "cmp", 4, .absolute(.none, true)),
            0xCE: Opcode(dec, "dec", 6, .absolute(.none, true)),
            0xD0: Opcode(bne, "bne", 2, .relative),
            0xD1: Opcode(cmp, "cmp", 5, .indirect(.y)),
            0xD5: Opcode(cmp, "cmp", 4, .zeroPage(.x)),
            0xD6: Opcode(dec, "dec", 6, .zeroPage(.x)),
            0xD8: Opcode(cld, "cld", 2, .implied),
            0xD9: Opcode(cmp, "cmp", 4, .absolute(.y, true)),
            0xDD: Opcode(cmp, "cmp", 4, .absolute(.x, true)),
            0xDE: Opcode(dec, "dec", 7, .absolute(.x, true)),
            0xE0: Opcode(cpx, "cpx", 2, .immediate),
            0xE1: Opcode(sbc, "sbc", 6, .indirect(.x)),
            0xE4: Opcode(cpx, "cpx", 3, .zeroPage(.none)),
            0xE5: Opcode(sbc, "sbc", 3, .zeroPage(.none)),
            0xE6: Opcode(inc, "inc", 5, .zeroPage(.none)),
            0xE8: Opcode(inx, "inx", 2, .implied),
            0xE9: Opcode(sbc, "sbc", 2, .immediate),
            0xEA: Opcode(nop, "nop", 2, .implied),
            0xEC: Opcode(cpx, "cpx", 4, .absolute(.none, true)),
            0xED: Opcode(sbc, "sbc", 4, .absolute(.none, true)),
            0xEE: Opcode(inc, "inc", 6, .absolute(.none, true)),
            0xF0: Opcode(beq, "beq", 2, .relative),
            0xF1: Opcode(sbc, "sbc", 5, .indirect(.y)),
            0xF5: Opcode(sbc, "sbc", 4, .zeroPage(.x)),
            0xF6: Opcode(inc, "inc", 6, .zeroPage(.x)),
            0xF8: Opcode(sed, "sed", 2, .implied),
            0xF9: Opcode(sbc, "sbc", 4, .absolute(.y, true)),
            0xFD: Opcode(sbc, "sbc", 4, .absolute(.x, true)),
            0xFE: Opcode(inc, "inc", 7, .absolute(.x, true))
        ]
    }

    func requestInterrupt(type: InterruptType) {
        // maybe handle interrupt priority as described in this document at page 13
        // http://nesdev.com/NESDoc.pdf
        guard type != .irq || self.regs.p.isNotSet(.interrupt) else {
            return
        }

        self.interruptRequest = type

        // maybe will have to switch to a queue of interrupts ?
    }

    // Method used to inject instructions for testing
    func process(opcode: Byte, operand: Operand = Operand()) {
        guard let opcode: Opcode = self.opcodes[opcode] else {
            fatalError("Unknown opcode used (outside of the 151 available)")
        }

        var operand = operand
        opcode.closure(&operand)
    }

//    var trace = [Word](repeating: 0, count: 50)

    @discardableResult
    func step() -> UInt8 {
        if self.stallCycles > 0 {
            self.stallCycles--
            self.totalCycles++
            return 1
        }

        if let interrupt = self.interruptRequest {
            let cycles = self.interrupt(type: interrupt)
            self.totalCycles &+= UInt64(cycles)
            return  cycles
        }

        let opcodeHex: Byte = self.memory.readByte(at: regs.pc)
//        self.trace.append(regs.pc)
//        self.trace.removeFirst()
        regs.pc++

        guard let opcode: Opcode = self.opcodes[opcodeHex] else {
            fatalError("Unknown opcode used (outside of the 151 available)")
        }

        var operand: Operand = self.buildOperand(using: opcode.addressingMode)
        opcode.closure(&operand)

        let cycles = opcode.cycles + operand.additionalCycles
        self.totalCycles &+= UInt64(cycles)
        return cycles
    }

    @discardableResult
    private func interrupt(type: InterruptType) -> UInt8 {
        self.interruptRequest = nil

        if type == .reset {
            self.regs.sp = 0xFD
        } else {
            stack.pushWord(data: regs.pc)
            stack.pushByte(data: regs.p.value | Flag.alwaysOne.rawValue)
        }

        self.regs.p.set(.interrupt)
        self.regs.pc = memory.readWord(at: type.address)

        return 7
    }

    private func buildOperand(using addressingMode: AddressingMode) -> Operand {
        switch addressingMode {
        case .zeroPage(let alteration):
            let alterationValue: Byte = alteration != .none ? (alteration == .x ? regs.x : regs.y) : 0
            var operand = Operand()
            operand.address = (self.memory.readByte(at: regs.pc).asWord() + alterationValue) & 0xFF
            operand.value = self.memory.readByte(at: operand.address).asWord()
            regs.pc++
            return operand
        case .absolute(let alteration, let shouldFetchValue):
            let alterationValue: Byte = alteration != .none ? (alteration == .x ? regs.x : regs.y) : 0
            var operand = Operand()
            operand.address = self.memory.readWord(at: regs.pc) + alterationValue
            if shouldFetchValue { operand.value = self.memory.readByte(at: operand.address).asWord() }
            regs.pc += 2
            operand.additionalCycles = alteration == .none
                ? 0
                : UInt8(operand.address.isAtSamePage(than: operand.address - (alteration == .x
                    ? regs.x
                    : regs.y)))
            return operand
        case .relative:
            var operand = Operand()

            // transform the relative address into an absolute address
            let value = self.memory.readByte(at: regs.pc)
            regs.pc++
            operand.address = regs.pc
            if value.isSignBitOn() {
                operand.address -= Word(128 - value & 0b01111111)
            } else {
                operand.address += value.asWord() & 0b01111111
            }

            operand.additionalCycles = UInt8(regs.pc.isAtSamePage(than: operand.address))
            return operand
        case .indirect(let alteration):
            let addressPointer: Word = ((alteration == .none
                ? self.memory.readWord(at: regs.pc)
                : self.memory.readByte(at: regs.pc).asWord())
                + (alteration == .x ? regs.x.asWord() : 0))
                & (alteration == .none ? 0xFFFF : 0xFF)

            var operand = Operand()
            operand.address = self.memory.readWordGlitched(at: addressPointer) &+ (alteration == .y ? regs.y : 0)
            operand.value = self.memory.readByte(at: operand.address).asWord()

            regs.pc += alteration == .none ? 2 : 1
            operand.additionalCycles = alteration == .y ? UInt8(operand.address.isAtSamePage(than: operand.address &- regs.y)) : 0
            return operand
        case .immediate:
            var operand = Operand()
            operand.value = self.memory.readByte(at: regs.pc).asWord()
            regs.pc++
            return operand
        case .implied, .accumulator: fallthrough
        default: return Operand()
        }
    }

    // OPCODES IMPLEMENTATION
    private func nop(_ operand: inout Operand) {}

    // Math
    private func inx(_ operand: inout Operand) { regs.x++; regs.p.updateFor(regs.x) }
    private func iny(_ operand: inout Operand) { regs.y++; regs.p.updateFor(regs.y) }
    private func dex(_ operand: inout Operand) { regs.x--; regs.p.updateFor(regs.x) }
    private func dey(_ operand: inout Operand) { regs.y--; regs.p.updateFor(regs.y) }

    private func adc(_ operand: inout Operand) {
        let result: Word = regs.a &+ operand.value &+ regs.p.valueOf(.carry)
        regs.p.set(.carry, if: result.overflowsByte())
        regs.p.set(.overflow, if: Bool(~(regs.a ^ operand.value) & Word(regs.a ^ result) & Word(Flag.negative.rawValue)))
        regs.a = result.rightByte()
        regs.p.updateFor(regs.a)
    }

    private func sbc(_ operand: inout Operand) {
        let result: Word = regs.a &- operand.value &- (1 - regs.p.valueOf(.carry))
        regs.p.set(.carry, if: !result.overflowsByte())
        regs.p.set(.overflow, if: Bool((regs.a ^ operand.value) & Word(regs.a ^ result) & Word(Flag.negative.rawValue)))
        regs.a = result.rightByte()
        regs.p.updateFor(regs.a)
    }

    private func inc(_ operand: inout Operand) {
        let result: Byte = operand.value.rightByte() &+ 1
        memory.writeByte(result, at: operand.address)
        regs.p.updateFor(result)
    }

    private func dec(_ operand: inout Operand) {
        let result: Byte = operand.value.rightByte() &- 1
        memory.writeByte(result, at: operand.address)
        regs.p.updateFor(result)
    }

    // Bitwise
    private func and(_ operand: inout Operand) { regs.a &= Byte(operand.value); regs.p.updateFor(regs.a) }
    private func eor(_ operand: inout Operand) { regs.a ^= Byte(operand.value); regs.p.updateFor(regs.a) }
    private func ora(_ operand: inout Operand) { regs.a |= Byte(operand.value); regs.p.updateFor(regs.a) }

    private func bit(_ operand: inout Operand) {
        regs.p.set(.zero, if: !Bool(regs.a & Byte(operand.value)))
        regs.p.set(.overflow, if: Bool(Flag.overflow.rawValue & Byte(operand.value)))
        regs.p.set(.negative, if: Bool(Flag.negative.rawValue & Byte(operand.value)))
    }

    private func asl(_ operand: inout Operand) {
        regs.p.set(.carry, if: operand.value.rightByte().isMostSignificantBitOn())
        let result: Byte = operand.value.rightByte() << 1
        regs.p.updateFor(result)
        memory.writeByte(result, at: operand.address)
    }

    private func lsr(_ operand: inout Operand) {
        regs.p.set(.carry, if: operand.value.rightByte().isLeastSignificantBitOn())
        let result: Byte = operand.value.rightByte() >> 1
        regs.p.updateFor(result)
        memory.writeByte(result, at: operand.address)
    }

    private func rol(_ operand: inout Operand) {
        let result: Word = operand.value << 1 | Word(regs.p.valueOf(.carry))
        regs.p.set(.carry, if: Bool(result & 0x100))
        memory.writeByte(result.rightByte(), at: operand.address)
        regs.p.updateFor(result)
    }

    private func ror(_ operand: inout Operand) {
        let carry: Byte = regs.p.valueOf(.carry)
        regs.p.set(.carry, if: operand.value.isLeastSignificantBitOn())
        let result: Byte = operand.value.rightByte() >> 1 | carry << 7
        regs.p.updateFor(result)
        memory.writeByte(result, at: operand.address)
    }

    private func asla(_ operand: inout Operand) {
        regs.p.set(.carry, if: regs.a.isMostSignificantBitOn())
        regs.a <<= 1
        regs.p.updateFor(regs.a)
    }

    private func lsra(_ operand: inout Operand) {
        regs.p.set(.carry, if: regs.a.isLeastSignificantBitOn())
        regs.a >>= 1
        regs.p.updateFor(regs.a)
    }

    private func rola(_ operand: inout Operand) {
        let carry: Byte = regs.p.valueOf(.carry)
        regs.p.set(.carry, if: regs.a.isSignBitOn())
        regs.a = regs.a << 1 | carry
        regs.p.updateFor(regs.a)
    }

    private func rora(_ operand: inout Operand) {
        let carry: Byte = regs.p.valueOf(.carry)
        regs.p.set(.carry, if: regs.a.isLeastSignificantBitOn())
        regs.a = regs.a >> 1 | carry << 7
        regs.p.updateFor(regs.a)
    }

    // flags
    private func clc(_ operand: inout Operand) { regs.p.unset(.carry) }
    private func cld(_ operand: inout Operand) { regs.p.unset(.decimal) }
    private func cli(_ operand: inout Operand) { regs.p.unset(.interrupt) }
    private func clv(_ operand: inout Operand) { regs.p.unset(.overflow) }
    private func sec(_ operand: inout Operand) { regs.p.set(.carry) }
    private func sed(_ operand: inout Operand) { regs.p.set(.decimal) }
    private func sei(_ operand: inout Operand) { regs.p.set(.interrupt) }

    // comparison
    private func compare(_ register: Byte, _ value: Word) {
        regs.p.updateFor(register &- value.rightByte())
        regs.p.set(.carry, if: register >= value)
    }
    private func cmp(_ operand: inout Operand) { compare(regs.a, operand.value) }
    private func cpx(_ operand: inout Operand) { compare(regs.x, operand.value) }
    private func cpy(_ operand: inout Operand) { compare(regs.y, operand.value) }

    // branches
    private func branch(to operand: inout Operand, if condition: Bool) {
        guard condition else {
            operand.additionalCycles = 0
            return
        }

        regs.pc = operand.address
        operand.additionalCycles++
    }
    private func beq(_ operand: inout Operand) { branch(to: &operand, if: regs.p.isSet(.zero)) }
    private func bne(_ operand: inout Operand) { branch(to: &operand, if: !regs.p.isSet(.zero)) }
    private func bmi(_ operand: inout Operand) { branch(to: &operand, if: regs.p.isSet(.negative)) }
    private func bpl(_ operand: inout Operand) { branch(to: &operand, if: !regs.p.isSet(.negative)) }
    private func bcs(_ operand: inout Operand) { branch(to: &operand, if: regs.p.isSet(.carry)) }
    private func bcc(_ operand: inout Operand) { branch(to: &operand, if: !regs.p.isSet(.carry)) }
    private func bvs(_ operand: inout Operand) { branch(to: &operand, if: regs.p.isSet(.overflow)) }
    private func bvc(_ operand: inout Operand) { branch(to: &operand, if: !regs.p.isSet(.overflow)) }

    // jump
    private func jmp(_ operand: inout Operand) { regs.pc = operand.address }

    // subroutines
    private func jsr(_ operand: inout Operand) { stack.pushWord(data: regs.pc &- 1); regs.pc = operand.address }
    private func rts(_ operand: inout Operand) { regs.pc = stack.popWord() &+ 1 }

    // interruptions
    private func rti(_ operand: inout Operand) {
        regs.p &= stack.popByte() | Flag.alwaysOne.rawValue
        regs.pc = stack.popWord()
    }

    private func brk(_ operand: inout Operand) {
        self.regs.p.set(.breaks)
        self.interrupt(type: .irq)
    }

    // stack
    private func pha(_ operand: inout Operand) { stack.pushByte(data: regs.a) }
    private func php(_ operand: inout Operand) { stack.pushByte(data: regs.p.value | (.alwaysOne | .breaks)) }
    private func pla(_ operand: inout Operand) { regs.a = stack.popByte(); regs.p.updateFor(regs.a) }
    private func plp(_ operand: inout Operand) { regs.p &= stack.popByte() & ~Flag.breaks.rawValue | Flag.alwaysOne.rawValue }

    // loading
    private func load(_ a: inout Byte, _ operand: Word) { a = operand.rightByte(); regs.p.updateFor(a) }
    private func lda(_ operand: inout Operand) { self.load(&regs.a, operand.value) }
    private func ldx(_ operand: inout Operand) { self.load(&regs.x, operand.value) }
    private func ldy(_ operand: inout Operand) { self.load(&regs.y, operand.value) }

    // storing
    private func sta(_ operand: inout Operand) { memory.writeByte(regs.a, at: operand.address) }
    private func stx(_ operand: inout Operand) { memory.writeByte(regs.x, at: operand.address) }
    private func sty(_ operand: inout Operand) { memory.writeByte(regs.y, at: operand.address) }

    // transfering
    private func transfer(_ a: inout Byte, _ b: Byte) { a = b; regs.p.updateFor(a) }
    private func tax(_ operand: inout Operand) { self.transfer(&regs.x, regs.a) }
    private func txa(_ operand: inout Operand) { self.transfer(&regs.a, regs.x) }
    private func tay(_ operand: inout Operand) { self.transfer(&regs.y, regs.a) }
    private func tya(_ operand: inout Operand) { self.transfer(&regs.a, regs.y) }
    private func tsx(_ operand: inout Operand) { self.transfer(&regs.x, regs.sp) }
    private func txs(_ operand: inout Operand) { regs.sp = regs.x }
}
