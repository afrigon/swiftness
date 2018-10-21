//
//  cpu.swift
//  swift-nes
//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

typealias Byte = UInt8
typealias Word = UInt16
typealias DWord = UInt32
typealias QWord = UInt64

typealias AccumulatorRegister = Byte
typealias XIndexRegister = Byte
typealias YIndexRegister = Byte
typealias ProcessorStatusRegister = Byte
typealias StackPointerRegister = Byte
typealias ProgramCounterRegister = Word

struct RegisterSet {
    var a: AccumulatorRegister      = 0x00
    var x: XIndexRegister           = 0x00
    var y: YIndexRegister           = 0x00
    var p: ProcessorStatusRegister  = 0x00
    var sp: StackPointerRegister     = 0x00
    var pc: ProgramCounterRegister  = 0x0000
    
    mutating func set(_ flag: Flag, _ value: Bool? = nil) {
        if value == nil {
            return self.p |= flag.rawValue
        }
        
        self.p = value! ?
            self.p | flag.rawValue :
            self.p & ~flag.rawValue
    }
    
    mutating func unset(_ flag: Flag) {
        self.p &= ~flag.rawValue
    }
    
    mutating func setZeroNegative(_ value: Byte) {
        self.set(Flag.zero, value == 0)
        self.set(Flag.negative, (value & 0b10000000) != 0)
    }
}

enum Endian {
    case little
    case big
}

enum Flag: UInt8 {
    case carry = 1
    case zero = 2
    case interrupt = 4
    case decimal = 8
    case breaks = 16
    case alwaysOne = 32
    case overflow = 64
    case negative = 128
}

enum AddressingMode {
    case accumulator
    case implied
    case immediate
    case zeroPage
    case zeroPageX
    case zeroPageY
    case relative
    case absolute
    case absoluteX
    case absoluteY
    case indirect
    case indirectX
    case indirectY
}

typealias Operation = InstructionSet
enum InstructionSet {
    case nop    // nothing
    
    // math
    case adc    // addition
    case sbc    // substraction
    case inc    // increment
    case inx    // increment x
    case iny    // increment y
    case dec    // decrement
    case dex    // decrement x
    case dey    // decrement y
    
    // bit manipulation
    case and    // and
    case bit    // research needed !
    case eor    // xor
    case ora    // or
    case asl    // left shift by 1
    case lsr    // right shift by 1
    case rol    // rotate left by 1
    case ror    // rotate right by 1
    
    // accumulator
    case asla   // left shift a by 1
    case lsra   // right shift a by 1
    case rola   // rotate left a by 1
    case rora   // rotate right a by 1
    
    // flags
    case clc    // clear carry
    case cld    // clear decimal mode
    case cli    // clear interupt disable status
    case clv    // clear overflow
    case sec    // set carry
    case sed    // set decimal mode
    case sei    // set interupt disable status
    
    // comparison
    case cmp    // compare with A
    case cpx    // compare with X
    case cpy    // compare with Y
    
    // branch
    case beq    // branch if result == 0
    case bmi    // branch if result < 0
    case bne    // branch if result != 0
    case bpl    // branch if result > 0
    
    // flag branch
    case bcc    // branch if carry == 0
    case bcs    // branch if carry == 1
    case bvc    // branch if overflow == 0
    case bvs    // branch if overflow == 1
    
    // jump
    case jmp    // jump to location
    
    // subroutines
    case jsr    // push PC, jmp
    case rts    // return from subroutine
    
    // interuptions
    case rti    // return from interrupt
    case brk    // force break
    
    // stack
    case pha    // push A
    case php    // push P
    case pla    // pop A
    case plp    // pop P
    
    // loading
    case lda    // load into A
    case ldx    // load into X
    case ldy    // load into Y
    
    // storing
    case sta    // store from A
    case stx    // store from X
    case sty    // store from Y
    
    // transfering
    case tax    // mov  X, A
    case tay    // mov  Y, A
    case tsx    // mov  X, S
    case txa    // mov  A, X
    case txs    // mov  S, X
    case tya    // mov  A, Y
}

struct Opcode {
    let operation: Operation
    let addressingMode: AddressingMode
    let cycles: UInt8
    let implemented: Bool
    let closure: () -> Void
    
    init(_ operation: Operation, _ addresingMode: AddressingMode, _ cycles: UInt8, implemented: Bool = true, _ closure: () -> Void) {
        self.operation = operation
        self.addressingMode = addresingMode
        self.cycles = implemented ? cycles : 1
        self.implemented = implemented
    }
}

//struct Instruction {
//    let opcode: Opcode
//    let operand: Word
//}

enum InterruptAddress: Word {
    case nmi = 0xFFFA
    case reset = 0xFFFC
    case irq = 0xFFFE
}

//struct Operand {
//    let value: Word
//    let address: Word
//}

class CoreProcessingUnit {
    private var opcodes: [Byte: Opcode] = [:]
    private let endian: Endian = .little
    private let memory = CoreProcesingUnitMemoryMap()
    private var regs = RegisterSet()
    private var totalCycles: UInt64 = 0
    
    // arguments
    private var operand: Word = 0x0000
    private var address: Word = 0x0000
    
    private var additionalCycles: UInt8 = 0
    
    init() {
        self.opcodes = [
            0x00: Opcode(.brk, .implied, 7, brk),
            0x01: Opcode(.ora, .indirectX, 6, ora),
            0x05: Opcode(.ora, .zeroPage, 3, ora),
            0x06: Opcode(.asl, .zeroPage, 5, asl),
            0x08: Opcode(.php, .implied, 3, brk),
            0x09: Opcode(.ora, .immediate, 2, ora),
            0x0A: Opcode(.asla, .accumulator, 2, brk),
            0x0D: Opcode(.ora, .absolute, 4, ora),
            0x0E: Opcode(.asl, .absolute, 6, asl),
            0x10: Opcode(.bpl, .implied, 2, bpl),
            0x11: Opcode(.ora, .indirectY, 5, ora),
            0x15: Opcode(.ora, .zeroPageX, 4, ora),
            0x16: Opcode(.asl, .zeroPageX, 6, asl),
            0x18: Opcode(.clc, .implied, 2, clc),
            0x19: Opcode(.ora, .absoluteY, 4, ora),
            0x1D: Opcode(.ora, .absoluteX, 4, ora),
            0x1E: Opcode(.asl, .absoluteX, 7, asl),
            0x20: Opcode(.jsr, .implied, 6, jsr),
            0x21: Opcode(.and, .indirectX, 6, and),
            0x24: Opcode(.bit, .zeroPage, 3, bit),
            0x25: Opcode(.and, .zeroPage, 3, and),
            0x26: Opcode(.rol, .zeroPage, 5, rol),
            0x28: Opcode(.plp, .implied, 4, plp),
            0x29: Opcode(.and, .immediate, 2, and),
            0x2A: Opcode(.rola, .accumulator, 2, rola),
            0x2C: Opcode(.bit, .absolute, 4, bit),
            0x2D: Opcode(.and, .absolute, 2, and),
            0x2E: Opcode(.rol, .absolute, 6, rol),
            0x30: Opcode(.bmi, .implied, 2, bmi),
            0x31: Opcode(.and, .indirectY, 5, and),
            0x35: Opcode(.and, .zeroPageX, 4, and),
            0x36: Opcode(.rol, .zeroPageX, 6, rol),
            0x38: Opcode(.sec, .implied, 2, sec),
            0x39: Opcode(.and, .absoluteY, 4, and),
            0x3D: Opcode(.and, .absoluteX, 4, and),
            0x3E: Opcode(.rol, .absoluteX, 7, rol),
            0x40: Opcode(.rti, .implied, 6, rti),
            0x41: Opcode(.eor, .indirectX, 6, eor),
            0x45: Opcode(.eor, .zeroPage, 3, eor),
            0x46: Opcode(.lsr, .zeroPage, 5, lsr),
            0x48: Opcode(.pha, .implied, 3, pha),
            0x49: Opcode(.eor, .immediate, 2, eor),
            0x4A: Opcode(.lsra, .accumulator, 2, lsra),
            0x4C: Opcode(.jmp, .absolute, 3, jmp),
            0x4D: Opcode(.eor, .absolute, 4, eor),
            0x4E: Opcode(.lsr, .absolute, 6, lsr),
            0x50: Opcode(.bvc, .implied, 2, bvc),
            0x51: Opcode(.eor, .indirectY, 5, eor),
            0x55: Opcode(.eor, .zeroPageX, 4, eor),
            0x56: Opcode(.lsr, .zeroPageX, 6, lsr),
            0x58: Opcode(.cli, .implied, 2, cli),
            0x59: Opcode(.eor, .absoluteY, 4, eor),
            0x5D: Opcode(.eor, .absoluteX, 4, eor),
            0x5E: Opcode(.lsr, .absoluteX, 7, lsr),
            0x60: Opcode(.rts, .implied, 6, rts),
            0x61: Opcode(.adc, .indirectX, 6, adc),
            0x65: Opcode(.adc, .zeroPage, 3, adc),
            0x66: Opcode(.ror, .zeroPage, 5, ror),
            0x68: Opcode(.pla, .implied, 4, pla),
            0x69: Opcode(.adc, .immediate, 2, adc),
            0x6A: Opcode(.rora, .accumulator, 2, rora),
            0x6C: Opcode(.jmp, .indirect, 5, jmp),
            0x6D: Opcode(.adc, .absolute, 4, adc),
            0x6E: Opcode(.ror, .absolute, 6, ror),
            0x70: Opcode(.bvs, .implied, 2, bvs),
            0x71: Opcode(.adc, .indirectY, 5, adc),
            0x75: Opcode(.adc, .zeroPageX, 4, adc),
            0x76: Opcode(.ror, .zeroPageX, 6, ror),
            0x78: Opcode(.sei, .implied, 2, sei),
            0x79: Opcode(.adc, .absoluteY, 4, adc),
            0x7D: Opcode(.adc, .absoluteX, 4, adc),
            0x7E: Opcode(.ror, .absoluteX, 7, ror),
            0x81: Opcode(.sta, .indirectX, 6, sta),
            0x84: Opcode(.sty, .zeroPage, 3, sty),
            0x85: Opcode(.sta, .zeroPage, 3, sta),
            0x86: Opcode(.stx, .zeroPage, 3, stx),
            0x88: Opcode(.dey, .implied, 2, dey),
            0x8A: Opcode(.txa, .implied, 2, txa),
            0x8C: Opcode(.sty, .absolute, 4, sty),
            0x8D: Opcode(.sta, .absolute, 4, sta),
            0x8E: Opcode(.stx, .absolute, 4, stx),
            0x90: Opcode(.bcc, .implied, 2, bcc),
            0x91: Opcode(.sta, .indirectY, 6, sta),
            0x94: Opcode(.sty, .zeroPageX, 4, sty),
            0x95: Opcode(.sta, .zeroPageX, 4, sta),
            0x96: Opcode(.stx, .zeroPageY, 4, stx),
            0x98: Opcode(.tya, .implied, 2, tya),
            0x99: Opcode(.sta, .absoluteY, 5, sta),
            0x9A: Opcode(.txs, .implied, 2, txs),
            0x9D: Opcode(.sta, .absoluteX, 5, sta),
            0xA0: Opcode(.ldy, .immediate, 2, ldy),
            0xA1: Opcode(.lda, .indirectX, 6, lda),
            0xA2: Opcode(.ldx, .immediate, 2, ldx),
            0xA4: Opcode(.ldy, .zeroPage, 3, ldy),
            0xA5: Opcode(.lda, .zeroPage, 3, lda),
            0xA6: Opcode(.ldx, .zeroPage, 3, ldx),
            0xA8: Opcode(.tay, .implied, 2, tay),
            0xA9: Opcode(.lda, .immediate, 2, lda),
            0xAA: Opcode(.tax, .implied, 2, tax),
            0xAC: Opcode(.ldy, .absolute, 4, ldy),
            0xAD: Opcode(.lda, .absolute, 4, lda),
            0xAE: Opcode(.ldx, .absolute, 4, ldx),
            0xB0: Opcode(.bcs, .implied, 2, bcs),
            0xB1: Opcode(.lda, .indirectY, 5, lda),
            0xB4: Opcode(.ldy, .zeroPageX, 4, ldy),
            0xB5: Opcode(.lda, .zeroPageX, 4, lda),
            0xB6: Opcode(.ldx, .zeroPageY, 4, ldx),
            0xB8: Opcode(.clv, .implied, 2, clv),
            0xB9: Opcode(.lda, .absoluteY, 4, lda),
            0xBA: Opcode(.tsx, .implied, 2, tsx),
            0xBC: Opcode(.ldy, .absoluteX, 4, ldy),
            0xBD: Opcode(.lda, .absoluteX, 4, lda),
            0xBE: Opcode(.ldx, .absoluteY, 4, ldx),
            0xC0: Opcode(.cpy, .immediate, 2, cpy),
            0xC1: Opcode(.cmp, .indirectX, 6, cmp),
            0xC4: Opcode(.cpy, .zeroPage, 3, cpy),
            0xC5: Opcode(.cmp, .zeroPage, 3, cmp),
            0xC6: Opcode(.dec, .zeroPage, 5, dec),
            0xC8: Opcode(.iny, .implied, 2, iny),
            0xC9: Opcode(.cmp, .immediate, 2, cmp),
            0xCA: Opcode(.dex, .implied, 2, dex),
            0xCC: Opcode(.cpy, .absolute, 4, cpy),
            0xCD: Opcode(.cmp, .absolute, 4, cmp),
            0xCE: Opcode(.dec, .absolute, 6, dec),
            0xD0: Opcode(.bne, .implied, 2, bne),
            0xD1: Opcode(.cmp, .indirectY, 5, cmp),
            0xD5: Opcode(.cmp, .zeroPageX, 4, cmp),
            0xD6: Opcode(.dec, .zeroPageX, 6, dec),
            0xD8: Opcode(.cld, .implied, 2, cld),
            0xD9: Opcode(.cmp, .absoluteY, 4, cmp),
            0xDD: Opcode(.cmp, .absoluteX, 4, cmp),
            0xDE: Opcode(.dec, .absoluteX, 7, dec),
            0xE0: Opcode(.cpx, .immediate, 2, cpx),
            0xE1: Opcode(.sbc, .indirectX, 6, sbc),
            0xE4: Opcode(.cpx, .zeroPage, 3, cpx),
            0xE5: Opcode(.sbc, .zeroPage, 3, sbc),
            0xE6: Opcode(.inc, .zeroPage, 5, inc),
            0xE8: Opcode(.inx, .implied, 2, inx),
            0xE9: Opcode(.sbc, .immediate, 2, sbc),
            0xEA: Opcode(.nop, .implied, 2, nop),
            0xEC: Opcode(.cpx, .absolute, 4, cpx),
            0xED: Opcode(.sbc, .absolute, 4, sbc),
            0xEE: Opcode(.inc, .absolute, 6, inc),
            0xF0: Opcode(.beq, .implied, 2, beq),
            0xF1: Opcode(.sbc, .indirectY, 5, sbc),
            0xF5: Opcode(.sbc, .zeroPageX, 4, sbc),
            0xF6: Opcode(.inc, .zeroPageX, 6, inc),
            0xF8: Opcode(.sed, .implied, 2, sed),
            0xF9: Opcode(.sbc, .absoluteY, 4, sbc),
            0xFD: Opcode(.sbc, .absoluteX, 4, sbc),
            0xFE: Opcode(.inc, .absoluteX, 7, inc)
        ]
    }
    
    func run(cycles: inout UInt64) {
        while (cycles > 0) {
            let opcodeHex = Byte(self.memory.readByte(at: regs.pc))
            regs.pc++
            
            guard let opcode: Opcode = self.opcodes[opcodeHex] else {
                fatalError("Unknown opcode used (outside of the 151 available)")
            }
            
            self.getOperands(using: opcode.addressingMode)
            opcode.closure()
            
            cycles -= UInt64(opcode.cycles + self.additionalCycles);
            //self.totalcpu_cycles -= self.cycles;
            self.additionalCycles = 0
        }
    }
    
    func interrupt() {
        
    }
    
    func reset() {
        self.regs.pc = InterruptAddress.reset.rawValue
        self.regs.sp -= 3
        self.regs.set(Flag.interrupt)
    }
    
    private func getOperands(using addressingMode: AddressingMode = .implied) {
        self.operand = 0x0000
        switch addressingMode {
        case .zeroPage: // pc* is the address to operand
            address = memory.readByte(at: regs.pc)
            operand = memory.readByte(at: address)
            regs.pc++
            break
        case .zeroPageX: // pc* + x is the address to operand
            address = (memory.readByte(at: regs.pc) + regs.x) & 0xff
            operand = memory.readByte(at: address)
            regs.pc++
            break
        case .zeroPageY: // pc* + y is the address to operand
            address = (memory.readByte(at: regs.pc) + regs.y) & 0xff
            operand = memory.readByte(at: address)
            regs.pc++
            break
        case .absolute: // word pc* is the address to operand
            address = memory.readWord(at: regs.pc)
            operand = memory.readByte(at: address)
            regs.pc += 2
            break
        case .absoluteX: // word pc* + x is the address to operand
            address = memory.readWord(at: regs.pc) + regs.x
            operand = memory.readByte(at: address)
            regs.pc += 2
            self.checkPages()
            break
        case .absoluteY: // word pc* + y is the address to operand
            address = memory.readWord(at: regs.pc) + regs.y
            operand = memory.readByte(at: address)
            regs.pc += 2
            self.checkPages()
            break
        case .relative:
            address = memory.readByte(at: regs.pc)
            regs.pc++
            
            if address & 0x80 != 0 {
                address -= 0x100 + regs.pc
            }
            
            self.checkPages()
        case .indirect:
            let target: Word = memory.readWord(at: regs.pc)
            address = memory.readWordGlitched(at: target)
            regs.pc += 2
            break
        case .indirectX:
            let target: Word = memory.readByte(at: regs.pc)
            address = (memory.readByte(at: (target + regs.x + 1) & 0xFF) << 8) | memory.readByte(at: (target + regs.x) & 0xFF)
            operand = memory.readByte(at: address)
            regs.pc++
            break
        case .indirectY:
            let target: Word = memory.readByte(at: regs.pc)
            address = (((memory.readByte(at: (target + 1) & 0xFF) << 8) | memory.readByte(at: target)) + regs.y) & 0xFFFF
            operand = memory.readByte(at: address)
            regs.pc++
            self.checkPages()
            break
        case .immediate:
            self.operand = Word(self.memory.readByte(at: regs.pc))
            regs.pc++
            break
        case .accumulator: fallthrough
        case .implied: fallthrough
        default:
            return
        }
    }
    
    private func checkPages() {
        if (regs.pc >> 8 != self.address >> 8) {
            self.additionalCycles++
        }
    }
    
    private func brk() {
        memory.stack.pushWord(data: regs.pc - 1, sp: &regs.sp)
        memory.stack.pushByte(data: regs.p, sp: &regs.sp)
        regs.set(.alwaysOne)
        regs.pc = InterruptAddress.nmi.rawValue
    }
    
    private func ora() {
        regs.a |= Byte(operand)
        regs.setZeroNegative(Byte(operand))
    }
    
    private func asl() {
        regs.set(.carry, operand & 0b10000000 == 1)
        operand <<= 1
        regs.setZeroNegative(Byte(operand))
        memory.writeByte(Byte(operand), at: address)
    }
    
    private func asla() {
        regs.set(.carry, regs.a & 0b10000000 == 1)
        regs.a <<= 1
        regs.setZeroNegative(regs.a)
    }
    
    private func lsr() {
        regs.set(.carry, operand & 1 == 1)
        operand >>= 1
        regs.setZeroNegative(Byte(operand))
        memory.writeByte(Byte(operand), at: address)
    }
    
    private func lsra() {
        regs.set(.carry, regs.a & 1 == 1)
        regs.a >>= 1
        regs.setZeroNegative(regs.a)
    }
}
