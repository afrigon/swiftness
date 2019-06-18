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

struct Registers {
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

fileprivate struct Opcode {
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
    private var regs: Registers = Registers()
    private var opcodes: [Opcode?]! = nil
    private var interruptRequest: InterruptType?

    let frequency: Double = 1789773
    var stallCycles: UInt16 = 0
    var totalCycles: UInt64 = 0

    init(using bus: Bus) {
        self.bus = bus
        self.memory = CoreProcessingUnitMemory(using: bus)
        self.stack = Stack(using: self.bus, sp: &self.regs.sp)

        self.opcodes = [
            Opcode(brk, "brk", 7, .implied),                  // 0x00
            Opcode(ora, "ora", 6, .indirect(.x)),             // 0x01
            nil,                                              // 0x02
            nil,                                              // 0x03
            nil,                                              // 0x04
            Opcode(ora, "ora", 3, .zeroPage(.none)),          // 0x05
            Opcode(asl, "asl", 5, .zeroPage(.none)),          // 0x06
            nil,                                              // 0x07
            Opcode(php, "php", 3, .implied),                  // 0x08
            Opcode(ora, "ora", 2, .immediate),                // 0x09
            Opcode(asla, "asl", 2, .accumulator),             // 0x0A
            nil,                                              // 0x0B
            nil,                                              // 0x0C
            Opcode(ora, "ora", 4, .absolute(.none, true)),    // 0x0D
            Opcode(asl, "asl", 6, .absolute(.none, true)),    // 0x0E
            nil,                                              // 0x0F
            Opcode(bpl, "bpl", 2, .relative),                 // 0x10
            Opcode(ora, "ora", 5, .indirect(.y)),             // 0x11
            nil,                                              // 0x12
            nil,                                              // 0x13
            nil,                                              // 0x14
            Opcode(ora, "ora", 4, .zeroPage(.x)),             // 0x15
            Opcode(asl, "asl", 6, .zeroPage(.x)),             // 0x16
            nil,                                              // 0x17
            Opcode(clc, "clc", 2, .implied),                  // 0x18
            Opcode(ora, "ora", 4, .absolute(.y, true)),       // 0x19
            nil,                                              // 0x1A
            nil,                                              // 0x1B
            nil,                                              // 0x1C
            Opcode(ora, "ora", 4, .absolute(.x, true)),       // 0x1D
            Opcode(asl, "asl", 7, .absolute(.x, true)),       // 0x1E
            nil,                                              // 0x1F
            Opcode(jsr, "jsr", 6, .absolute(.none, false)),   // 0x20
            Opcode(and, "and", 6, .indirect(.x)),             // 0x21
            nil,                                              // 0x22
            nil,                                              // 0x23
            Opcode(bit, "bit", 3, .zeroPage(.none)),          // 0x24
            Opcode(and, "and", 3, .zeroPage(.none)),          // 0x25
            Opcode(rol, "rol", 5, .zeroPage(.none)),          // 0x26
            Opcode(plp, "plp", 4, .implied),                  // 0x28
            Opcode(and, "and", 2, .immediate),                // 0x29
            Opcode(rola, "rol", 2, .accumulator),             // 0x2A
            nil,                                              // 0x2B
            Opcode(bit, "bit", 4, .absolute(.none, true)),    // 0x2C
            Opcode(and, "and", 2, .absolute(.none, true)),    // 0x2D
            Opcode(rol, "rol", 6, .absolute(.none, true)),    // 0x2E
            nil,                                              // 0x2F
            Opcode(bmi, "bmi", 2, .relative),                 // 0x30
            Opcode(and, "and", 5, .indirect(.y)),             // 0x31
            nil,                                              // 0x32
            nil,                                              // 0x33
            nil,                                              // 0x34
            Opcode(and, "and", 4, .zeroPage(.x)),             // 0x35
            Opcode(rol, "rol", 6, .zeroPage(.x)),             // 0x36
            nil,                                              // 0x37
            Opcode(sec, "sec", 2, .implied),                  // 0x38
            Opcode(and, "and", 4, .absolute(.y, true)),       // 0x39
            nil,                                              // 0x3A
            nil,                                              // 0x3B
            nil,                                              // 0x3C
            Opcode(and, "and", 4, .absolute(.x, true)),       // 0x3D
            Opcode(rol, "rol", 7, .absolute(.x, true)),       // 0x3E
            nil,                                              // 0x3F
            Opcode(rti, "rti", 6, .implied),                  // 0x40
            Opcode(eor, "eor", 6, .indirect(.x)),             // 0x41
            nil,                                              // 0x42
            nil,                                              // 0x43
            nil,                                              // 0x44
            Opcode(eor, "eor", 3, .zeroPage(.none)),          // 0x45
            Opcode(lsr, "lsr", 5, .zeroPage(.none)),          // 0x46
            nil,                                              // 0x47
            Opcode(pha, "pha", 3, .implied),                  // 0x48
            Opcode(eor, "eor", 2, .immediate),                // 0x49
            Opcode(lsra, "lsr", 2, .accumulator),             // 0x4A
            nil,                                              // 0x4B
            Opcode(jmp, "jmp", 3, .absolute(.none, false)),   // 0x4C
            Opcode(eor, "eor", 4, .absolute(.none, true)),    // 0x4D
            Opcode(lsr, "lsr", 6, .absolute(.none, true)),    // 0x4E
            nil,                                              // 0x4F
            Opcode(bvc, "bvc", 2, .relative),                 // 0x50
            Opcode(eor, "eor", 5, .indirect(.y)),             // 0x51
            nil,                                              // 0x52
            nil,                                              // 0x53
            nil,                                              // 0x54
            Opcode(eor, "eor", 4, .zeroPage(.x)),             // 0x55
            Opcode(lsr, "lsr", 6, .zeroPage(.x)),             // 0x56
            nil,                                              // 0x57
            Opcode(cli, "cli", 2, .implied),                  // 0x58
            Opcode(eor, "eor", 4, .absolute(.y, true)),       // 0x59
            nil,                                              // 0x5A
            nil,                                              // 0x5B
            nil,                                              // 0x5C
            Opcode(eor, "eor", 4, .absolute(.x, true)),       // 0x5D
            Opcode(lsr, "lsr", 7, .absolute(.x, true)),       // 0x5E
            nil,                                              // 0x5F
            Opcode(rts, "rts", 6, .implied),                  // 0x60
            Opcode(adc, "adc", 6, .indirect(.x)),             // 0x61
            nil,                                              // 0x62
            nil,                                              // 0x63
            nil,                                              // 0x64
            Opcode(adc, "adc", 3, .zeroPage(.none)),          // 0x65
            Opcode(ror, "ror", 5, .zeroPage(.none)),          // 0x66
            nil,                                              // 0x67
            Opcode(pla, "pla", 4, .implied),                  // 0x68
            Opcode(adc, "adc", 2, .immediate),                // 0x69
            Opcode(rora, "ror", 2, .accumulator),             // 0x6A
            nil,                                              // 0x6B
            Opcode(jmp, "jmp", 5, .indirect(.none)),          // 0x6C
            Opcode(adc, "adc", 4, .absolute(.none, true)),    // 0x6D
            Opcode(ror, "ror", 6, .absolute(.none, true)),    // 0x6E
            nil,                                              // 0x6F
            Opcode(bvs, "bvs", 2, .relative),                 // 0x70
            Opcode(adc, "adc", 5, .indirect(.y)),             // 0x71
            nil,                                              // 0x72
            nil,                                              // 0x73
            nil,                                              // 0x74
            Opcode(adc, "adc", 4, .zeroPage(.x)),             // 0x75
            Opcode(ror, "ror", 6, .zeroPage(.x)),             // 0x76
            nil,                                              // 0x77
            Opcode(sei, "sei", 2, .implied),                  // 0x78
            Opcode(adc, "adc", 4, .absolute(.y, true)),       // 0x79
            nil,                                              // 0x7A
            nil,                                              // 0x7B
            nil,                                              // 0x7C
            Opcode(adc, "adc", 4, .absolute(.x, true)),       // 0x7D
            Opcode(ror, "ror", 7, .absolute(.x, true)),       // 0x7E
            nil,                                              // 0x7F
            nil,                                              // 0x80
            Opcode(sta, "sta", 6, .indirect(.x)),             // 0x81
            nil,                                              // 0x82
            nil,                                              // 0x83
            Opcode(sty, "sty", 3, .zeroPage(.none)),          // 0x84
            Opcode(sta, "sta", 3, .zeroPage(.none)),          // 0x85
            Opcode(stx, "stx", 3, .zeroPage(.none)),          // 0x86
            nil,                                              // 0x87
            Opcode(dey, "dey", 2, .implied),                  // 0x88
            nil,                                              // 0x89
            Opcode(txa, "txa", 2, .implied),                  // 0x8A
            nil,                                              // 0x8B
            Opcode(sty, "sty", 4, .absolute(.none, false)),   // 0x8C
            Opcode(sta, "sta", 4, .absolute(.none, false)),   // 0x8D
            Opcode(stx, "stx", 4, .absolute(.none, false)),   // 0x8E
            nil,                                              // 0x8F
            Opcode(bcc, "bcc", 2, .relative),                 // 0x90
            Opcode(sta, "sta", 6, .indirect(.y)),             // 0x91
            nil,                                              // 0x92
            nil,                                              // 0x93
            Opcode(sty, "sty", 4, .zeroPage(.x)),             // 0x94
            Opcode(sta, "sta", 4, .zeroPage(.x)),             // 0x95
            Opcode(stx, "stx", 4, .zeroPage(.y)),             // 0x96
            nil,                                              // 0x97
            Opcode(tya, "tya", 2, .implied),                  // 0x98
            Opcode(sta, "sta", 5, .absolute(.y, false)),      // 0x99
            Opcode(txs, "txs", 2, .implied),                  // 0x9A
            nil,                                              // 0x9B
            nil,                                              // 0x9C
            Opcode(sta, "sta", 5, .absolute(.x, false)),      // 0x9D
            nil,                                              // 0x9E
            nil,                                              // 0x9F
            Opcode(ldy, "ldy", 2, .immediate),                // 0xA0
            Opcode(lda, "lda", 6, .indirect(.x)),             // 0xA1
            Opcode(ldx, "ldx", 2, .immediate),                // 0xA2
            nil,                                              // 0xA3
            Opcode(ldy, "ldy", 3, .zeroPage(.none)),          // 0xA4
            Opcode(lda, "lda", 3, .zeroPage(.none)),          // 0xA5
            Opcode(ldx, "ldx", 3, .zeroPage(.none)),          // 0xA6
            nil,                                              // 0xA7
            Opcode(tay, "tay", 2, .implied),                  // 0xA8
            Opcode(lda, "lda", 2, .immediate),                // 0xA9
            Opcode(tax, "tax", 2, .implied),                  // 0xAA
            nil,                                              // 0xAB
            Opcode(ldy, "ldy", 4, .absolute(.none, true)),    // 0xAC
            Opcode(lda, "lda", 4, .absolute(.none, true)),    // 0xAD
            Opcode(ldx, "ldx", 4, .absolute(.none, true)),    // 0xAE
            nil,                                              // 0xAF
            Opcode(bcs, "bcs", 2, .relative),                 // 0xB0
            Opcode(lda, "lda", 5, .indirect(.y)),             // 0xB1
            nil,                                              // 0xB2
            nil,                                              // 0xB3
            Opcode(ldy, "ldy", 4, .zeroPage(.x)),             // 0xB4
            Opcode(lda, "lda", 4, .zeroPage(.x)),             // 0xB5
            Opcode(ldx, "ldx", 4, .zeroPage(.y)),             // 0xB6
            nil,                                              // 0xB7
            Opcode(clv, "clv", 2, .implied),                  // 0xB8
            Opcode(lda, "lda", 4, .absolute(.y, true)),       // 0xB9
            Opcode(tsx, "tsx", 2, .implied),                  // 0xBA
            nil,                                              // 0xBB
            Opcode(ldy, "ldy", 4, .absolute(.x, true)),       // 0xBC
            Opcode(lda, "lda", 4, .absolute(.x, true)),       // 0xBD
            Opcode(ldx, "ldx", 4, .absolute(.y, true)),       // 0xBE
            nil,                                              // 0xBF
            Opcode(cpy, "cpy", 2, .immediate),                // 0xC0
            Opcode(cmp, "cmp", 6, .indirect(.x)),             // 0xC1
            nil,                                              // 0xC2
            nil,                                              // 0xC3
            Opcode(cpy, "cpy", 3, .zeroPage(.none)),          // 0xC4
            Opcode(cmp, "cmp", 3, .zeroPage(.none)),          // 0xC5
            Opcode(dec, "dec", 5, .zeroPage(.none)),          // 0xC6
            nil,                                              // 0xC7
            Opcode(iny, "iny", 2, .implied),                  // 0xC8
            Opcode(cmp, "cmp", 2, .immediate),                // 0xC9
            Opcode(dex, "dex", 2, .implied),                  // 0xCA
            nil,                                              // 0xCB
            Opcode(cpy, "cpy", 4, .absolute(.none, true)),    // 0xCC
            Opcode(cmp, "cmp", 4, .absolute(.none, true)),    // 0xCD
            Opcode(dec, "dec", 6, .absolute(.none, true)),    // 0xCE
            nil,                                              // 0xCF
            Opcode(bne, "bne", 2, .relative),                 // 0xD0
            Opcode(cmp, "cmp", 5, .indirect(.y)),             // 0xD1
            nil,                                              // 0xD2
            nil,                                              // 0xD3
            nil,                                              // 0xD4
            Opcode(cmp, "cmp", 4, .zeroPage(.x)),             // 0xD5
            Opcode(dec, "dec", 6, .zeroPage(.x)),             // 0xD6
            nil,                                              // 0xD7
            Opcode(cld, "cld", 2, .implied),                  // 0xD8
            Opcode(cmp, "cmp", 4, .absolute(.y, true)),       // 0xD9
            nil,                                              // 0xDA
            nil,                                              // 0xDB
            nil,                                              // 0xDC
            Opcode(cmp, "cmp", 4, .absolute(.x, true)),       // 0xDD
            Opcode(dec, "dec", 7, .absolute(.x, true)),       // 0xDE
            nil,                                              // 0xDF
            Opcode(cpx, "cpx", 2, .immediate),                // 0xE0
            Opcode(sbc, "sbc", 6, .indirect(.x)),             // 0xE1
            nil,                                              // 0xE2
            nil,                                              // 0xE3
            Opcode(cpx, "cpx", 3, .zeroPage(.none)),          // 0xE4
            Opcode(sbc, "sbc", 3, .zeroPage(.none)),          // 0xE5
            Opcode(inc, "inc", 5, .zeroPage(.none)),          // 0xE6
            nil,                                              // 0xE7
            Opcode(inx, "inx", 2, .implied),                  // 0xE8
            Opcode(sbc, "sbc", 2, .immediate),                // 0xE9
            Opcode(nop, "nop", 2, .implied),                  // 0xEA
            nil,                                              // 0xEB
            Opcode(cpx, "cpx", 4, .absolute(.none, true)),    // 0xEC
            Opcode(sbc, "sbc", 4, .absolute(.none, true)),    // 0xED
            Opcode(inc, "inc", 6, .absolute(.none, true)),    // 0xEE
            nil,                                              // 0xEF
            Opcode(beq, "beq", 2, .relative),                 // 0xF0
            Opcode(sbc, "sbc", 5, .indirect(.y)),             // 0xF1
            nil,                                              // 0xF2
            nil,                                              // 0xF3
            nil,                                              // 0xF4
            Opcode(sbc, "sbc", 4, .zeroPage(.x)),             // 0xF5
            Opcode(inc, "inc", 6, .zeroPage(.x)),             // 0xF6
            nil,                                              // 0xF7
            Opcode(sed, "sed", 2, .implied),                  // 0xF8
            Opcode(sbc, "sbc", 4, .absolute(.y, true)),       // 0xF9
            nil,                                              // 0xFA
            nil,                                              // 0xFB
            nil,                                              // 0xFC
            Opcode(sbc, "sbc", 4, .absolute(.x, true)),       // 0xFD
            Opcode(inc, "inc", 7, .absolute(.x, true)),       // 0xFE
            nil,                                              // 0xFF
        ]
    }

    func requestInterrupt(type: InterruptType) {
        guard type != .irq || self.regs.p.isNotSet(.interrupt) else { return }
        self.interruptRequest = type
    }

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
            self.stack.pushWord(data: self.regs.pc)
            self.stack.pushByte(data: self.regs.p.value | Flag.alwaysOne.rawValue)
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
