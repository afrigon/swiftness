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

struct Opcode {
    let closure: (inout Operand) -> Void
    let name: String
    let cycles: UInt8
    let addressingMode: AddressingMode
}

struct Operand {
    var value: Word = 0x0000
    var address: Word = 0x0000
    var additionalCycles: UInt8 = 0
}

class CoreProcessingUnit {
    private weak var bus: Bus!

    private let memory: CoreProcessingUnitMemory
    private let stack: Stack
    private var regs: Registers = Registers()
    private var opcodes: [Byte: Opcode]! = nil
    private var interruptRequest: InterruptType?

    let frequency: Double = 1789773
    var stallCycles: UInt16 = 0
    var totalCycles: UInt64 = 0

    init(using bus: Bus) {
        self.bus = bus
        self.memory = CoreProcessingUnitMemory(using: bus)
        self.stack = Stack(using: self.bus, sp: &self.regs.sp)

        self.opcodes = [
            0x00: Opcode(closure: brk, name: "brk", cycles: 7, addressingMode: .implied),
            0x01: Opcode(closure: ora, name: "ora", cycles: 6, addressingMode: .indirect(.x)),
            0x05: Opcode(closure: ora, name: "ora", cycles: 3, addressingMode: .zeroPage(.none)),
            0x06: Opcode(closure: asl, name: "asl", cycles: 5, addressingMode: .zeroPage(.none)),
            0x08: Opcode(closure: php, name: "php", cycles: 3, addressingMode: .implied),
            0x09: Opcode(closure: ora, name: "ora", cycles: 2, addressingMode: .immediate),
            0x0A: Opcode(closure: asla, name: "asl", cycles: 2, addressingMode: .accumulator),
            0x0D: Opcode(closure: ora, name: "ora", cycles: 4, addressingMode: .absolute(.none, true)),
            0x0E: Opcode(closure: asl, name: "asl", cycles: 6, addressingMode: .absolute(.none, true)),
            0x10: Opcode(closure: bpl, name: "bpl", cycles: 2, addressingMode: .relative),
            0x11: Opcode(closure: ora, name: "ora", cycles: 5, addressingMode: .indirect(.y)),
            0x15: Opcode(closure: ora, name: "ora", cycles: 4, addressingMode: .zeroPage(.x)),
            0x16: Opcode(closure: asl, name: "asl", cycles: 6, addressingMode: .zeroPage(.x)),
            0x18: Opcode(closure: clc, name: "clc", cycles: 2, addressingMode: .implied),
            0x19: Opcode(closure: ora, name: "ora", cycles: 4, addressingMode: .absolute(.y, true)),
            0x1D: Opcode(closure: ora, name: "ora", cycles: 4, addressingMode: .absolute(.x, true)),
            0x1E: Opcode(closure: asl, name: "asl", cycles: 7, addressingMode: .absolute(.x, true)),
            0x20: Opcode(closure: jsr, name: "jsr", cycles: 6, addressingMode: .absolute(.none, false)),
            0x21: Opcode(closure: and, name: "and", cycles: 6, addressingMode: .indirect(.x)),
            0x24: Opcode(closure: bit, name: "bit", cycles: 3, addressingMode: .zeroPage(.none)),
            0x25: Opcode(closure: and, name: "and", cycles: 3, addressingMode: .zeroPage(.none)),
            0x26: Opcode(closure: rol, name: "rol", cycles: 5, addressingMode: .zeroPage(.none)),
            0x28: Opcode(closure: plp, name: "plp", cycles: 4, addressingMode: .implied),
            0x29: Opcode(closure: and, name: "and", cycles: 2, addressingMode: .immediate),
            0x2A: Opcode(closure: rola, name: "rol", cycles: 2, addressingMode: .accumulator),
            0x2C: Opcode(closure: bit, name: "bit", cycles: 4, addressingMode: .absolute(.none, true)),
            0x2D: Opcode(closure: and, name: "and", cycles: 2, addressingMode: .absolute(.none, true)),
            0x2E: Opcode(closure: rol, name: "rol", cycles: 6, addressingMode: .absolute(.none, true)),
            0x30: Opcode(closure: bmi, name: "bmi", cycles: 2, addressingMode: .relative),
            0x31: Opcode(closure: and, name: "and", cycles: 5, addressingMode: .indirect(.y)),
            0x35: Opcode(closure: and, name: "and", cycles: 4, addressingMode: .zeroPage(.x)),
            0x36: Opcode(closure: rol, name: "rol", cycles: 6, addressingMode: .zeroPage(.x)),
            0x38: Opcode(closure: sec, name: "sec", cycles: 2, addressingMode: .implied),
            0x39: Opcode(closure: and, name: "and", cycles: 4, addressingMode: .absolute(.y, true)),
            0x3D: Opcode(closure: and, name: "and", cycles: 4, addressingMode: .absolute(.x, true)),
            0x3E: Opcode(closure: rol, name: "rol", cycles: 7, addressingMode: .absolute(.x, true)),
            0x40: Opcode(closure: rti, name: "rti", cycles: 6, addressingMode: .implied),
            0x41: Opcode(closure: eor, name: "eor", cycles: 6, addressingMode: .indirect(.x)),
            0x45: Opcode(closure: eor, name: "eor", cycles: 3, addressingMode: .zeroPage(.none)),
            0x46: Opcode(closure: lsr, name: "lsr", cycles: 5, addressingMode: .zeroPage(.none)),
            0x48: Opcode(closure: pha, name: "pha", cycles: 3, addressingMode: .implied),
            0x49: Opcode(closure: eor, name: "eor", cycles: 2, addressingMode: .immediate),
            0x4A: Opcode(closure: lsra, name: "lsr", cycles: 2, addressingMode: .accumulator),
            0x4C: Opcode(closure: jmp, name: "jmp", cycles: 3, addressingMode: .absolute(.none, false)),
            0x4D: Opcode(closure: eor, name: "eor", cycles: 4, addressingMode: .absolute(.none, true)),
            0x4E: Opcode(closure: lsr, name: "lsr", cycles: 6, addressingMode: .absolute(.none, true)),
            0x50: Opcode(closure: bvc, name: "bvc", cycles: 2, addressingMode: .relative),
            0x51: Opcode(closure: eor, name: "eor", cycles: 5, addressingMode: .indirect(.y)),
            0x55: Opcode(closure: eor, name: "eor", cycles: 4, addressingMode: .zeroPage(.x)),
            0x56: Opcode(closure: lsr, name: "lsr", cycles: 6, addressingMode: .zeroPage(.x)),
            0x58: Opcode(closure: cli, name: "cli", cycles: 2, addressingMode: .implied),
            0x59: Opcode(closure: eor, name: "eor", cycles: 4, addressingMode: .absolute(.y, true)),
            0x5D: Opcode(closure: eor, name: "eor", cycles: 4, addressingMode: .absolute(.x, true)),
            0x5E: Opcode(closure: lsr, name: "lsr", cycles: 7, addressingMode: .absolute(.x, true)),
            0x60: Opcode(closure: rts, name: "rts", cycles: 6, addressingMode: .implied),
            0x61: Opcode(closure: adc, name: "adc", cycles: 6, addressingMode: .indirect(.x)),
            0x65: Opcode(closure: adc, name: "adc", cycles: 3, addressingMode: .zeroPage(.none)),
            0x66: Opcode(closure: ror, name: "ror", cycles: 5, addressingMode: .zeroPage(.none)),
            0x68: Opcode(closure: pla, name: "pla", cycles: 4, addressingMode: .implied),
            0x69: Opcode(closure: adc, name: "adc", cycles: 2, addressingMode: .immediate),
            0x6A: Opcode(closure: rora, name: "ror", cycles: 2, addressingMode: .accumulator),
            0x6C: Opcode(closure: jmp, name: "jmp", cycles: 5, addressingMode: .indirect(.none)),
            0x6D: Opcode(closure: adc, name: "adc", cycles: 4, addressingMode: .absolute(.none, true)),
            0x6E: Opcode(closure: ror, name: "ror", cycles: 6, addressingMode: .absolute(.none, true)),
            0x70: Opcode(closure: bvs, name: "bvs", cycles: 2, addressingMode: .relative),
            0x71: Opcode(closure: adc, name: "adc", cycles: 5, addressingMode: .indirect(.y)),
            0x75: Opcode(closure: adc, name: "adc", cycles: 4, addressingMode: .zeroPage(.x)),
            0x76: Opcode(closure: ror, name: "ror", cycles: 6, addressingMode: .zeroPage(.x)),
            0x78: Opcode(closure: sei, name: "sei", cycles: 2, addressingMode: .implied),
            0x79: Opcode(closure: adc, name: "adc", cycles: 4, addressingMode: .absolute(.y, true)),
            0x7D: Opcode(closure: adc, name: "adc", cycles: 4, addressingMode: .absolute(.x, true)),
            0x7E: Opcode(closure: ror, name: "ror", cycles: 7, addressingMode: .absolute(.x, true)),
            0x81: Opcode(closure: sta, name: "sta", cycles: 6, addressingMode: .indirect(.x)),
            0x84: Opcode(closure: sty, name: "sty", cycles: 3, addressingMode: .zeroPage(.none)),
            0x85: Opcode(closure: sta, name: "sta", cycles: 3, addressingMode: .zeroPage(.none)),
            0x86: Opcode(closure: stx, name: "stx", cycles: 3, addressingMode: .zeroPage(.none)),
            0x88: Opcode(closure: dey, name: "dey", cycles: 2, addressingMode: .implied),
            0x8A: Opcode(closure: txa, name: "txa", cycles: 2, addressingMode: .implied),
            0x8C: Opcode(closure: sty, name: "sty", cycles: 4, addressingMode: .absolute(.none, false)),
            0x8D: Opcode(closure: sta, name: "sta", cycles: 4, addressingMode: .absolute(.none, false)),
            0x8E: Opcode(closure: stx, name: "stx", cycles: 4, addressingMode: .absolute(.none, false)),
            0x90: Opcode(closure: bcc, name: "bcc", cycles: 2, addressingMode: .relative),
            0x91: Opcode(closure: sta, name: "sta", cycles: 6, addressingMode: .indirect(.y)),
            0x94: Opcode(closure: sty, name: "sty", cycles: 4, addressingMode: .zeroPage(.x)),
            0x95: Opcode(closure: sta, name: "sta", cycles: 4, addressingMode: .zeroPage(.x)),
            0x96: Opcode(closure: stx, name: "stx", cycles: 4, addressingMode: .zeroPage(.y)),
            0x98: Opcode(closure: tya, name: "tya", cycles: 2, addressingMode: .implied),
            0x99: Opcode(closure: sta, name: "sta", cycles: 5, addressingMode: .absolute(.y, false)),
            0x9A: Opcode(closure: txs, name: "txs", cycles: 2, addressingMode: .implied),
            0x9D: Opcode(closure: sta, name: "sta", cycles: 5, addressingMode: .absolute(.x, false)),
            0xA0: Opcode(closure: ldy, name: "ldy", cycles: 2, addressingMode: .immediate),
            0xA1: Opcode(closure: lda, name: "lda", cycles: 6, addressingMode: .indirect(.x)),
            0xA2: Opcode(closure: ldx, name: "ldx", cycles: 2, addressingMode: .immediate),
            0xA4: Opcode(closure: ldy, name: "ldy", cycles: 3, addressingMode: .zeroPage(.none)),
            0xA5: Opcode(closure: lda, name: "lda", cycles: 3, addressingMode: .zeroPage(.none)),
            0xA6: Opcode(closure: ldx, name: "ldx", cycles: 3, addressingMode: .zeroPage(.none)),
            0xA8: Opcode(closure: tay, name: "tay", cycles: 2, addressingMode: .implied),
            0xA9: Opcode(closure: lda, name: "lda", cycles: 2, addressingMode: .immediate),
            0xAA: Opcode(closure: tax, name: "tax", cycles: 2, addressingMode: .implied),
            0xAC: Opcode(closure: ldy, name: "ldy", cycles: 4, addressingMode: .absolute(.none, true)),
            0xAD: Opcode(closure: lda, name: "lda", cycles: 4, addressingMode: .absolute(.none, true)),
            0xAE: Opcode(closure: ldx, name: "ldx", cycles: 4, addressingMode: .absolute(.none, true)),
            0xB0: Opcode(closure: bcs, name: "bcs", cycles: 2, addressingMode: .relative),
            0xB1: Opcode(closure: lda, name: "lda", cycles: 5, addressingMode: .indirect(.y)),
            0xB4: Opcode(closure: ldy, name: "ldy", cycles: 4, addressingMode: .zeroPage(.x)),
            0xB5: Opcode(closure: lda, name: "lda", cycles: 4, addressingMode: .zeroPage(.x)),
            0xB6: Opcode(closure: ldx, name: "ldx", cycles: 4, addressingMode: .zeroPage(.y)),
            0xB8: Opcode(closure: clv, name: "clv", cycles: 2, addressingMode: .implied),
            0xB9: Opcode(closure: lda, name: "lda", cycles: 4, addressingMode: .absolute(.y, true)),
            0xBA: Opcode(closure: tsx, name: "tsx", cycles: 2, addressingMode: .implied),
            0xBC: Opcode(closure: ldy, name: "ldy", cycles: 4, addressingMode: .absolute(.x, true)),
            0xBD: Opcode(closure: lda, name: "lda", cycles: 4, addressingMode: .absolute(.x, true)),
            0xBE: Opcode(closure: ldx, name: "ldx", cycles: 4, addressingMode: .absolute(.y, true)),
            0xC0: Opcode(closure: cpy, name: "cpy", cycles: 2, addressingMode: .immediate),
            0xC1: Opcode(closure: cmp, name: "cmp", cycles: 6, addressingMode: .indirect(.x)),
            0xC4: Opcode(closure: cpy, name: "cpy", cycles: 3, addressingMode: .zeroPage(.none)),
            0xC5: Opcode(closure: cmp, name: "cmp", cycles: 3, addressingMode: .zeroPage(.none)),
            0xC6: Opcode(closure: dec, name: "dec", cycles: 5, addressingMode: .zeroPage(.none)),
            0xC8: Opcode(closure: iny, name: "iny", cycles: 2, addressingMode: .implied),
            0xC9: Opcode(closure: cmp, name: "cmp", cycles: 2, addressingMode: .immediate),
            0xCA: Opcode(closure: dex, name: "dex", cycles: 2, addressingMode: .implied),
            0xCC: Opcode(closure: cpy, name: "cpy", cycles: 4, addressingMode: .absolute(.none, true)),
            0xCD: Opcode(closure: cmp, name: "cmp", cycles: 4, addressingMode: .absolute(.none, true)),
            0xCE: Opcode(closure: dec, name: "dec", cycles: 6, addressingMode: .absolute(.none, true)),
            0xD0: Opcode(closure: bne, name: "bne", cycles: 2, addressingMode: .relative),
            0xD1: Opcode(closure: cmp, name: "cmp", cycles: 5, addressingMode: .indirect(.y)),
            0xD5: Opcode(closure: cmp, name: "cmp", cycles: 4, addressingMode: .zeroPage(.x)),
            0xD6: Opcode(closure: dec, name: "dec", cycles: 6, addressingMode: .zeroPage(.x)),
            0xD8: Opcode(closure: cld, name: "cld", cycles: 2, addressingMode: .implied),
            0xD9: Opcode(closure: cmp, name: "cmp", cycles: 4, addressingMode: .absolute(.y, true)),
            0xDD: Opcode(closure: cmp, name: "cmp", cycles: 4, addressingMode: .absolute(.x, true)),
            0xDE: Opcode(closure: dec, name: "dec", cycles: 7, addressingMode: .absolute(.x, true)),
            0xE0: Opcode(closure: cpx, name: "cpx", cycles: 2, addressingMode: .immediate),
            0xE1: Opcode(closure: sbc, name: "sbc", cycles: 6, addressingMode: .indirect(.x)),
            0xE4: Opcode(closure: cpx, name: "cpx", cycles: 3, addressingMode: .zeroPage(.none)),
            0xE5: Opcode(closure: sbc, name: "sbc", cycles: 3, addressingMode: .zeroPage(.none)),
            0xE6: Opcode(closure: inc, name: "inc", cycles: 5, addressingMode: .zeroPage(.none)),
            0xE8: Opcode(closure: inx, name: "inx", cycles: 2, addressingMode: .implied),
            0xE9: Opcode(closure: sbc, name: "sbc", cycles: 2, addressingMode: .immediate),
            0xEA: Opcode(closure: nop, name: "nop", cycles: 2, addressingMode: .implied),
            0xEC: Opcode(closure: cpx, name: "cpx", cycles: 4, addressingMode: .absolute(.none, true)),
            0xED: Opcode(closure: sbc, name: "sbc", cycles: 4, addressingMode: .absolute(.none, true)),
            0xEE: Opcode(closure: inc, name: "inc", cycles: 6, addressingMode: .absolute(.none, true)),
            0xF0: Opcode(closure: beq, name: "beq", cycles: 2, addressingMode: .relative),
            0xF1: Opcode(closure: sbc, name: "sbc", cycles: 5, addressingMode: .indirect(.y)),
            0xF5: Opcode(closure: sbc, name: "sbc", cycles: 4, addressingMode: .zeroPage(.x)),
            0xF6: Opcode(closure: inc, name: "inc", cycles: 6, addressingMode: .zeroPage(.x)),
            0xF8: Opcode(closure: sed, name: "sed", cycles: 2, addressingMode: .implied),
            0xF9: Opcode(closure: sbc, name: "sbc", cycles: 4, addressingMode: .absolute(.y, true)),
            0xFD: Opcode(closure: sbc, name: "sbc", cycles: 4, addressingMode: .absolute(.x, true)),
            0xFE: Opcode(closure: inc, name: "inc", cycles: 7, addressingMode: .absolute(.x, true))
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
