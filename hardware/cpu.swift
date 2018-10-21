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
    var s: StackPointerRegister     = 0x00
    var pc: ProgramCounterRegister  = 0x0000
}

enum Endian {
    case little
    case big
}

enum Flags: UInt8 {
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
    let cpuCycle: UInt8
    let implemented: Bool
    
    init(_ operation: Operation, _ addresingMode: AddressingMode, _ cpuCycle: UInt8, implemented: Bool = true) {
        self.operation = operation
        self.addressingMode = addresingMode
        self.cpuCycle = implemented ? cpuCycle : 1
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

class CoreProcessingUnit {
    private let opcodes: [Byte: Opcode] = [
        0x00: Opcode(.brk, .implied, 2),
        0x01: Opcode(.ora, .indirectX, 2),
        0x05: Opcode(.ora, .zeroPage, 2),
        0x06: Opcode(.asl, .zeroPage, 2),
        0x08: Opcode(.php, .implied, 2),
        0x09: Opcode(.ora, .immediate, 2),
        0x0A: Opcode(.asl, .accumulator, 2),
        0x0D: Opcode(.ora, .absolute, 2),
        0x0E: Opcode(.asl, .absolute, 2),
        0x10: Opcode(.bpl, .implied, 2),
        0x11: Opcode(.ora, .indirectY, 2),
        0x15: Opcode(.ora, .zeroPageX, 2),
        0x16: Opcode(.asl, .zeroPageX, 2),
        0x18: Opcode(.clc, .implied, 2),
        0x19: Opcode(.ora, .absoluteY, 2),
        0x1D: Opcode(.ora, .absoluteX, 2),
        0x1E: Opcode(.asl, .absoluteX, 2),
        0x20: Opcode(.jsr, .implied, 2),
        0x21: Opcode(.and, .indirectX, 2),
        0x24: Opcode(.bit, .zeroPage, 2),
        0x25: Opcode(.and, .zeroPage, 2),
        0x26: Opcode(.rol, .zeroPage, 2),
        0x28: Opcode(.plp, .implied, 2),
        0x29: Opcode(.and, .immediate, 2),
        0x2A: Opcode(.rol, .accumulator, 2),
        0x2C: Opcode(.bit, .absolute, 2),
        0x2D: Opcode(.and, .absolute, 2),
        0x2E: Opcode(.rol, .absolute, 2),
        0x30: Opcode(.bmi, .implied, 2),
        0x31: Opcode(.and, .indirectY, 2),
        0x35: Opcode(.and, .zeroPageX, 2),
        0x36: Opcode(.rol, .zeroPageX, 2),
        0x38: Opcode(.sec, .implied, 2),
        0x39: Opcode(.and, .absoluteY, 2),
        0x3D: Opcode(.and, .absoluteX, 2),
        0x3E: Opcode(.rol, .absoluteX, 2),
        0x40: Opcode(.rti, .implied, 2),
        0x41: Opcode(.eor, .indirectX, 2),
        0x45: Opcode(.eor, .zeroPage, 2),
        0x46: Opcode(.lsr, .zeroPage, 2),
        0x48: Opcode(.pha, .implied, 2),
        0x49: Opcode(.eor, .immediate, 2),
        0x4A: Opcode(.lsr, .accumulator, 2),
        0x4C: Opcode(.jmp, .absolute, 2),
        0x4D: Opcode(.eor, .absolute, 2),
        0x4E: Opcode(.lsr, .absolute, 2),
        0x50: Opcode(.bvc, .implied, 2),
        0x51: Opcode(.eor, .indirectY, 2),
        0x55: Opcode(.eor, .zeroPageX, 2),
        0x56: Opcode(.lsr, .zeroPageX, 2),
        0x58: Opcode(.cli, .implied, 2),
        0x59: Opcode(.eor, .absoluteY, 2),
        0x5D: Opcode(.eor, .absoluteX, 2),
        0x5E: Opcode(.lsr, .absoluteX, 2),
        0x60: Opcode(.rts, .implied, 2),
        0x61: Opcode(.adc, .indirectX, 2),
        0x65: Opcode(.adc, .zeroPage, 2),
        0x66: Opcode(.ror, .zeroPage, 2),
        0x68: Opcode(.pla, .implied, 2),
        0x69: Opcode(.adc, .immediate, 2),
        0x6A: Opcode(.ror, .accumulator, 2),
        0x6C: Opcode(.jmp, .indirect, 2),
        0x6D: Opcode(.adc, .absolute, 2),
        0x6E: Opcode(.ror, .absolute, 2),
        0x70: Opcode(.bvs, .implied, 2),
        0x71: Opcode(.adc, .indirectY, 2),
        0x75: Opcode(.adc, .zeroPageX, 2),
        0x76: Opcode(.ror, .zeroPageX, 2),
        0x78: Opcode(.sei, .implied, 2),
        0x79: Opcode(.adc, .absoluteY, 2),
        0x7D: Opcode(.adc, .absoluteX, 2),
        0x7E: Opcode(.ror, .absoluteX, 2),
        0x81: Opcode(.sta, .indirectX, 2),
        0x84: Opcode(.sty, .zeroPage, 2),
        0x85: Opcode(.sta, .zeroPage, 2),
        0x86: Opcode(.stx, .zeroPage, 2),
        0x88: Opcode(.dey, .implied, 2),
        0x8A: Opcode(.txa, .implied, 2),
        0x8C: Opcode(.sty, .absolute, 2),
        0x8D: Opcode(.sta, .absolute, 2),
        0x8E: Opcode(.stx, .absolute, 2),
        0x90: Opcode(.bcc, .implied, 2),
        0x91: Opcode(.sta, .indirectY, 2),
        0x94: Opcode(.sty, .zeroPageX, 2),
        0x95: Opcode(.sta, .zeroPageX, 2),
        0x96: Opcode(.stx, .zeroPageY, 2),
        0x98: Opcode(.tya, .implied, 2),
        0x99: Opcode(.sta, .absoluteY, 2),
        0x9A: Opcode(.txs, .implied, 2),
        0x9D: Opcode(.sta, .absoluteX, 2),
        0xA0: Opcode(.ldy, .immediate, 2),
        0xA1: Opcode(.lda, .indirectX, 2),
        0xA2: Opcode(.ldx, .immediate, 2),
        0xA4: Opcode(.ldy, .zeroPage, 2),
        0xA5: Opcode(.lda, .zeroPage, 2),
        0xA6: Opcode(.ldx, .zeroPage, 2),
        0xA8: Opcode(.tay, .implied, 2),
        0xA9: Opcode(.lda, .immediate, 2),
        0xAA: Opcode(.tax, .implied, 2),
        0xAC: Opcode(.ldy, .absolute, 2),
        0xAD: Opcode(.lda, .absolute, 2),
        0xAE: Opcode(.ldx, .absolute, 2),
        0xB0: Opcode(.bcs, .implied, 2),
        0xB1: Opcode(.lda, .indirectY, 2),
        0xB4: Opcode(.ldy, .zeroPageX, 2),
        0xB5: Opcode(.lda, .zeroPageX, 2),
        0xB6: Opcode(.ldx, .zeroPageY, 2),
        0xB8: Opcode(.clv, .implied, 2),
        0xB9: Opcode(.lda, .absoluteY, 2),
        0xBA: Opcode(.tsx, .implied, 2),
        0xBC: Opcode(.ldy, .absoluteX, 2),
        0xBD: Opcode(.lda, .absoluteX, 2),
        0xBE: Opcode(.ldx, .absoluteY, 2),
        0xC0: Opcode(.cpy, .immediate, 2),
        0xC1: Opcode(.cmp, .indirectX, 2),
        0xC4: Opcode(.cpy, .zeroPage, 2),
        0xC5: Opcode(.cmp, .zeroPage, 2),
        0xC6: Opcode(.dec, .zeroPage, 2),
        0xC8: Opcode(.iny, .implied, 2),
        0xC9: Opcode(.cmp, .immediate, 2),
        0xCA: Opcode(.dex, .implied, 2),
        0xCC: Opcode(.cpy, .absolute, 2),
        0xCD: Opcode(.cmp, .absolute, 2),
        0xCE: Opcode(.dec, .absolute, 2),
        0xD0: Opcode(.bne, .implied, 2),
        0xD1: Opcode(.cmp, .indirectY, 2),
        0xD5: Opcode(.cmp, .zeroPageX, 2),
        0xD6: Opcode(.dec, .zeroPageX, 2),
        0xD8: Opcode(.cld, .implied, 2),
        0xD9: Opcode(.cmp, .absoluteY, 2),
        0xDD: Opcode(.cmp, .absoluteX, 2),
        0xDE: Opcode(.dec, .absoluteX, 2),
        0xE0: Opcode(.cpx, .immediate, 2),
        0xE1: Opcode(.sbc, .indirectX, 2),
        0xE4: Opcode(.cpx, .zeroPage, 2),
        0xE5: Opcode(.sbc, .zeroPage, 2),
        0xE6: Opcode(.inc, .zeroPage, 2),
        0xE8: Opcode(.inx, .implied, 2),
        0xE9: Opcode(.sbc, .immediate, 2),
        0xEA: Opcode(.nop, .implied, 2),
        0xEC: Opcode(.cpx, .absolute, 2),
        0xED: Opcode(.sbc, .absolute, 2),
        0xEE: Opcode(.inc, .absolute, 2),
        0xF0: Opcode(.beq, .implied, 2),
        0xF1: Opcode(.sbc, .indirectY, 2),
        0xF5: Opcode(.sbc, .zeroPageX, 2),
        0xF6: Opcode(.inc, .zeroPageX, 2),
        0xF8: Opcode(.sed, .implied, 2),
        0xF9: Opcode(.sbc, .absoluteY, 2),
        0xFD: Opcode(.sbc, .absoluteX, 2),
        0xFE: Opcode(.inc, .absoluteX, 2)
    ]
    private let endian: Endian = .little
    private let memory = CoreProcesingUnitMemoryMap()
    private var registers = RegisterSet()
    private var totalCycles: UInt64 = 0
    
    func run() {
        
    }
    
    func interrupt() {
        
    }
    
    func reset() {
        self.registers.pc = InterruptAddress.reset.rawValue
        self.registers.s -= 3
        self.registers.p |= Flags.interrupt.rawValue
    }
}
