//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Alexandre Frigon. All rights reserved.
//

typealias Byte = UInt8
typealias Word = UInt16
typealias DWord = UInt32
typealias QWord = UInt64

typealias AccumulatorRegister = Byte
typealias XIndexRegister = Byte
typealias YIndexRegister = Byte
typealias StackPointerRegister = Byte
typealias ProgramCounterRegister = Word

enum InterruptAddress: Word { case nmi = 0xFFFA, reset = 0xFFFC, irq = 0xFFFE }

class ProcessorStatusRegister {
    private var _value: Byte
    var value: Byte { return self._value }
    
    init(_ value: Byte) { self._value = value }
    static func &= (left: inout ProcessorStatusRegister, right: Byte) { left._value = right }
    
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
    var p: ProcessorStatusRegister  = ProcessorStatusRegister(0x34)
    var sp: StackPointerRegister    = 0xFD
    var pc: ProgramCounterRegister  = 0x0000
    
    func isAtSamePage(than address: Word) -> Bool {
        return self.pc >> 8 != address >> 8
    }
}

typealias Operation = InstructionSet
enum InstructionSet {
    case nop    // nothing
    
    // math
    case adc    // addition
    case sbc    // substraction
    case inc    // increment a
    case inx    // increment x
    case iny    // increment y
    case dec    // decrement a
    case dex    // decrement x
    case dey    // decrement y
    
    // bit manipulation
    case bit
    case and    // and
    case ora    // or
    case eor    // xor
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
    let cycles: UInt8
    let closure: (_ value: Word, _ address: Word) -> Void
    let addressingMode: AddressingMode
    
    init(_ operation: Operation, _ cycles: UInt8, _ closure: @escaping (_ value: Word, _ address: Word) -> Void,  _ addressingMode: AddressingMode) {
        self.operation = operation
        self.cycles = cycles
        self.closure = closure
        self.addressingMode = addressingMode
    }
}

enum AddressingMode {
    case immediate
    case relative
    case implied, accumulator
    case zeroPage(Alteration)
    case absolute(Alteration)
    case indirect(Alteration)
    enum Alteration: UInt8 { case none = 0, x = 1, y = 2 }
}

struct Operand {
    var value: Word
    var address: Word
    var additionalCycles: UInt8
    
    init(value: Word = 0, address: Word = 0, _ additionalCycles: UInt8 = 0) {
        self.value = value
        self.address = address
        self.additionalCycles = additionalCycles
    }
}

protocol OperandBuilder {
    func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand
}

class AlteredOperandBuilder: OperandBuilder {   // Abstract
    let alteration: AddressingMode.Alteration
    init(_ alteration: AddressingMode.Alteration = .none) { self.alteration = alteration }
    func evaluate(_ regs: inout RegisterSet, _ memory: CoreProcessingUnitMemory) -> Operand { return Operand() }
}

class EmptyOperandBuilder: OperandBuilder {
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
        var operand = Operand(value: 0, address: memory.readByte(at: regs.pc).asWord())
        
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
        let operand = Operand(value: memory.readByte(at: regs.pc).asWord())
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

class CoreProcessingUnit {
    private var opcodes: [Byte: Opcode] = [:]
    private let memory = CoreProcessingUnitMemory()
    private let stack: Stack!
    private var regs = RegisterSet()
    private var totalCycles: UInt64 = 0
    
    init() {
        self.stack = memory.stack
        self.opcodes = [
            0x00: Opcode(.brk, 7, self.brk, .implied),
            0x01: Opcode(.ora, 6, self.ora, .indirect(.x)),
            0x05: Opcode(.ora, 3, self.ora, .zeroPage(.none)),
            0x06: Opcode(.asl, 5, self.asl, .zeroPage(.none)),
            0x08: Opcode(.php, 3, self.brk, .implied),
            0x09: Opcode(.ora, 2, self.ora, .immediate),
            0x0A: Opcode(.asla, 2, self.brk, .accumulator),
            0x0D: Opcode(.ora, 4, self.ora, .absolute(.none)),
            0x0E: Opcode(.asl, 6, self.asl, .absolute(.none)),
            0x10: Opcode(.bpl, 2, self.bpl, .implied),
            0x11: Opcode(.ora, 5, self.ora, .indirect(.y)),
            0x15: Opcode(.ora, 4, self.ora, .zeroPage(.x)),
            0x16: Opcode(.asl, 6, self.asl, .zeroPage(.x)),
            0x18: Opcode(.clc, 2, self.clc, .implied),
            0x19: Opcode(.ora, 4, self.ora, .absolute(.y)),
            0x1D: Opcode(.ora, 4, self.ora, .absolute(.x)),
            0x1E: Opcode(.asl, 7, self.asl, .absolute(.x)),
            0x20: Opcode(.jsr, 6, self.jsr, .implied),
            0x21: Opcode(.and, 6, self.and, .indirect(.x)),
            0x24: Opcode(.bit, 3, self.bit, .zeroPage(.none)),
            0x25: Opcode(.and, 3, self.and, .zeroPage(.none)),
            0x26: Opcode(.rol, 5, self.rol, .zeroPage(.none)),
            0x28: Opcode(.plp, 4, self.plp, .implied),
            0x29: Opcode(.and, 2, self.and, .immediate),
            0x2A: Opcode(.rola, 2, self.rola, .accumulator),
            0x2C: Opcode(.bit, 4, self.bit, .absolute(.none)),
            0x2D: Opcode(.and, 2, self.and, .absolute(.none)),
            0x2E: Opcode(.rol, 6, self.rol, .absolute(.none)),
            0x30: Opcode(.bmi, 2, self.bmi, .implied),
            0x31: Opcode(.and, 5, self.and, .indirect(.y)),
            0x35: Opcode(.and, 4, self.and, .zeroPage(.x)),
            0x36: Opcode(.rol, 6, self.rol, .zeroPage(.x)),
            0x38: Opcode(.sec, 2, self.sec, .implied),
            0x39: Opcode(.and, 4, self.and, .absolute(.y)),
            0x3D: Opcode(.and, 4, self.and, .absolute(.x)),
            0x3E: Opcode(.rol, 7, self.rol, .absolute(.x)),
            0x40: Opcode(.rti, 6, self.rti, .implied),
            0x41: Opcode(.eor, 6, self.eor, .indirect(.x)),
            0x45: Opcode(.eor, 3, self.eor, .zeroPage(.none)),
            0x46: Opcode(.lsr, 5, self.lsr, .zeroPage(.none)),
            0x48: Opcode(.pha, 3, self.pha, .implied),
            0x49: Opcode(.eor, 2, self.eor, .immediate),
            0x4A: Opcode(.lsra, 2, self.lsra, .accumulator),
            0x4C: Opcode(.jmp, 3, self.jmp, .absolute(.none)),
            0x4D: Opcode(.eor, 4, self.eor, .absolute(.none)),
            0x4E: Opcode(.lsr, 6, self.lsr, .absolute(.none)),
            0x50: Opcode(.bvc, 2, self.bvc, .implied),
            0x51: Opcode(.eor, 5, self.eor, .indirect(.y)),
            0x55: Opcode(.eor, 4, self.eor, .zeroPage(.x)),
            0x56: Opcode(.lsr, 6, self.lsr, .zeroPage(.x)),
            0x58: Opcode(.cli, 2, self.cli, .implied),
            0x59: Opcode(.eor, 4, self.eor, .absolute(.y)),
            0x5D: Opcode(.eor, 4, self.eor, .absolute(.x)),
            0x5E: Opcode(.lsr, 7, self.lsr, .absolute(.x)),
            0x60: Opcode(.rts, 6, self.rts, .implied),
            0x61: Opcode(.adc, 6, self.adc, .indirect(.x)),
            0x65: Opcode(.adc, 3, self.adc, .zeroPage(.none)),
            0x66: Opcode(.ror, 5, self.ror, .zeroPage(.none)),
            0x68: Opcode(.pla, 4, self.pla, .implied),
            0x69: Opcode(.adc, 2, self.adc, .immediate),
            0x6A: Opcode(.rora, 2, self.rora, .accumulator),
            0x6C: Opcode(.jmp, 5, self.jmp, .indirect(.none)),
            0x6D: Opcode(.adc, 4, self.adc, .absolute(.none)),
            0x6E: Opcode(.ror, 6, self.ror, .absolute(.none)),
            0x70: Opcode(.bvs, 2, self.bvs, .implied),
            0x71: Opcode(.adc, 5, self.adc, .indirect(.y)),
            0x75: Opcode(.adc, 4, self.adc, .zeroPage(.x)),
            0x76: Opcode(.ror, 6, self.ror, .zeroPage(.x)),
            0x78: Opcode(.sei, 2, self.sei, .implied),
            0x79: Opcode(.adc, 4, self.adc, .absolute(.y)),
            0x7D: Opcode(.adc, 4, self.adc, .absolute(.x)),
            0x7E: Opcode(.ror, 7, self.ror, .absolute(.x)),
            0x81: Opcode(.sta, 6, self.sta, .indirect(.x)),
            0x84: Opcode(.sty, 3, self.sty, .zeroPage(.none)),
            0x85: Opcode(.sta, 3, self.sta, .zeroPage(.none)),
            0x86: Opcode(.stx, 3, self.stx, .zeroPage(.none)),
            0x88: Opcode(.dey, 2, self.dey, .implied),
            0x8A: Opcode(.txa, 2, self.txa, .implied),
            0x8C: Opcode(.sty, 4, self.sty, .absolute(.none)),
            0x8D: Opcode(.sta, 4, self.sta, .absolute(.none)),
            0x8E: Opcode(.stx, 4, self.stx, .absolute(.none)),
            0x90: Opcode(.bcc, 2, self.bcc, .implied),
            0x91: Opcode(.sta, 6, self.sta, .indirect(.y)),
            0x94: Opcode(.sty, 4, self.sty, .zeroPage(.x)),
            0x95: Opcode(.sta, 4, self.sta, .zeroPage(.x)),
            0x96: Opcode(.stx, 4, self.stx, .zeroPage(.y)),
            0x98: Opcode(.tya, 2, self.tya, .implied),
            0x99: Opcode(.sta, 5, self.sta, .absolute(.y)),
            0x9A: Opcode(.txs, 2, self.txs, .implied),
            0x9D: Opcode(.sta, 5, self.sta, .absolute(.x)),
            0xA0: Opcode(.ldy, 2, self.ldy, .immediate),
            0xA1: Opcode(.lda, 6, self.lda, .indirect(.x)),
            0xA2: Opcode(.ldx, 2, self.ldx, .immediate),
            0xA4: Opcode(.ldy, 3, self.ldy, .zeroPage(.none)),
            0xA5: Opcode(.lda, 3, self.lda, .zeroPage(.none)),
            0xA6: Opcode(.ldx, 3, self.ldx, .zeroPage(.none)),
            0xA8: Opcode(.tay, 2, self.tay, .implied),
            0xA9: Opcode(.lda, 2, self.lda, .immediate),
            0xAA: Opcode(.tax, 2, self.tax, .implied),
            0xAC: Opcode(.ldy, 4, self.ldy, .absolute(.none)),
            0xAD: Opcode(.lda, 4, self.lda, .absolute(.none)),
            0xAE: Opcode(.ldx, 4, self.ldx, .absolute(.none)),
            0xB0: Opcode(.bcs, 2, self.bcs, .implied),
            0xB1: Opcode(.lda, 5, self.lda, .indirect(.y)),
            0xB4: Opcode(.ldy, 4, self.ldy, .zeroPage(.x)),
            0xB5: Opcode(.lda, 4, self.lda, .zeroPage(.x)),
            0xB6: Opcode(.ldx, 4, self.ldx, .zeroPage(.y)),
            0xB8: Opcode(.clv, 2, self.clv, .implied),
            0xB9: Opcode(.lda, 4, self.lda, .absolute(.y)),
            0xBA: Opcode(.tsx, 2, self.tsx, .implied),
            0xBC: Opcode(.ldy, 4, self.ldy, .absolute(.x)),
            0xBD: Opcode(.lda, 4, self.lda, .absolute(.x)),
            0xBE: Opcode(.ldx, 4, self.ldx, .absolute(.y)),
            0xC0: Opcode(.cpy, 2, self.cpy, .immediate),
            0xC1: Opcode(.cmp, 6, self.cmp, .indirect(.x)),
            0xC4: Opcode(.cpy, 3, self.cpy, .zeroPage(.none)),
            0xC5: Opcode(.cmp, 3, self.cmp, .zeroPage(.none)),
            0xC6: Opcode(.dec, 5, self.dec, .zeroPage(.none)),
            0xC8: Opcode(.iny, 2, self.iny, .implied),
            0xC9: Opcode(.cmp, 2, self.cmp, .immediate),
            0xCA: Opcode(.dex, 2, self.dex, .implied),
            0xCC: Opcode(.cpy, 4, self.cpy, .absolute(.none)),
            0xCD: Opcode(.cmp, 4, self.cmp, .absolute(.none)),
            0xCE: Opcode(.dec, 6, self.dec, .absolute(.none)),
            0xD0: Opcode(.bne, 2, self.bne, .implied),
            0xD1: Opcode(.cmp, 5, self.cmp, .indirect(.y)),
            0xD5: Opcode(.cmp, 4, self.cmp, .zeroPage(.x)),
            0xD6: Opcode(.dec, 6, self.dec, .zeroPage(.x)),
            0xD8: Opcode(.cld, 2, self.cld, .implied),
            0xD9: Opcode(.cmp, 4, self.cmp, .absolute(.y)),
            0xDD: Opcode(.cmp, 4, self.cmp, .absolute(.x)),
            0xDE: Opcode(.dec, 7, self.dec, .absolute(.x)),
            0xE0: Opcode(.cpx, 2, self.cpx, .immediate),
            0xE1: Opcode(.sbc, 6, self.sbc, .indirect(.x)),
            0xE4: Opcode(.cpx, 3, self.cpx, .zeroPage(.none)),
            0xE5: Opcode(.sbc, 3, self.sbc, .zeroPage(.none)),
            0xE6: Opcode(.inc, 5, self.inc, .zeroPage(.none)),
            0xE8: Opcode(.inx, 2, self.inx, .implied),
            0xE9: Opcode(.sbc, 2, self.sbc, .immediate),
            0xEA: Opcode(.nop, 2, self.nop, .implied),
            0xEC: Opcode(.cpx, 4, self.cpx, .absolute(.none)),
            0xED: Opcode(.sbc, 4, self.sbc, .absolute(.none)),
            0xEE: Opcode(.inc, 6, self.inc, .absolute(.none)),
            0xF0: Opcode(.beq, 2, self.beq, .implied),
            0xF1: Opcode(.sbc, 5, self.sbc, .indirect(.y)),
            0xF5: Opcode(.sbc, 4, self.sbc, .zeroPage(.x)),
            0xF6: Opcode(.inc, 6, self.inc, .zeroPage(.x)),
            0xF8: Opcode(.sed, 2, self.sed, .implied),
            0xF9: Opcode(.sbc, 4, self.sbc, .absolute(.y)),
            0xFD: Opcode(.sbc, 4, self.sbc, .absolute(.x)),
            0xFE: Opcode(.inc, 7, self.inc, .absolute(.x))
        ]
    }
    
    func run(cycles: inout UInt64) {
        // TODO: remove this inout atrocity
        while (cycles > 0) {
            let opcodeHex: Byte = self.memory.readByte(at: regs.pc)
            regs.pc++
            
            guard let opcode: Opcode = self.opcodes[opcodeHex] else {
                fatalError("Unknown opcode used (outside of the 151 available)")
            }
            
            let operand: Operand = self.buildOperand(using: opcode.addressingMode)
            opcode.closure(operand.value, operand.address)
            
            cycles -= UInt64(opcode.cycles + operand.additionalCycles);
            self.totalCycles -= UInt64(opcode.cycles + operand.additionalCycles);
        }
    }
    
    func interrupt() {
        stack.pushWord(data: regs.pc, sp: &regs.sp)
        stack.pushByte(data: regs.p.value | Flag.alwaysOne.rawValue, sp: &regs.sp)
        regs.p.set(.interrupt)
        regs.pc = memory.readWord(at: InterruptAddress.nmi.rawValue)
        // cycles += 7 ?
    }
    
    func reset() {
        regs.pc = memory.readWord(at: InterruptAddress.reset.rawValue)
        regs.sp = 0xFD
        regs.p.set(.interrupt)
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
    private func nop (_ value: Word, _ address: Word) {}
    
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
    
    private func inx(_ value: Word, _ address: Word) { regs.x++; regs.p.updateFor(regs.x) }
    private func iny(_ value: Word, _ address: Word) { regs.y++; regs.p.updateFor(regs.y) }
    private func dex(_ value: Word, _ address: Word) { regs.x--; regs.p.updateFor(regs.x) }
    private func dey(_ value: Word, _ address: Word) { regs.y--; regs.p.updateFor(regs.y) }
    
    private func bit(_ value: Word, _ address: Word) {
        regs.p.set(.zero, if: Bool(regs.a & value))
        regs.p.set((.overflow | .negative) & value)
    }
    
    private func and(_ value: Word, _ address: Word) { regs.a &= value; regs.p.updateFor(regs.a) }
    private func eor(_ value: Word, _ address: Word) { regs.a ^= value; regs.p.updateFor(regs.a) }
    private func ora(_ value: Word, _ address: Word) { regs.a |= value; regs.p.updateFor(regs.a) }
    
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
        regs.p.updateFor(a - value.rightByte())
        regs.p.set(.carry, if: regs.a >= value)
    }
    private func cmp(_ value: Word, _ address: Word) { compare(regs.a, value) }
    private func cpx(_ value: Word, _ address: Word) { compare(regs.x, value) }
    private func cpy(_ value: Word, _ address: Word) { compare(regs.y, value) }
    
    // branches
    private func branch(to address: Word, if condition: Bool) { if condition { regs.pc = address } }
    private func beq(_ value: Word, _ address: Word) { branch(to: address, if: regs.p.isSet(.zero)) }
    private func bne(_ value: Word, _ address: Word) { branch(to: address, if: !regs.p.isSet(.zero)) }
    private func bmi(_ value: Word, _ address: Word) { branch(to: address, if: regs.p.isSet(.negative)) }
    private func bpl(_ value: Word, _ address: Word) { branch(to: address, if: !regs.p.isSet(.negative)) }
    private func bcs(_ value: Word, _ address: Word) { branch(to: address, if: regs.p.isSet(.carry)) }
    private func bcc(_ value: Word, _ address: Word) { branch(to: address, if: !regs.p.isSet(.carry)) }
    private func bvs(_ value: Word, _ address: Word) { branch(to: address, if: regs.p.isSet(.overflow)) }
    private func bvc(_ value: Word, _ address: Word) { branch(to: address, if: !regs.p.isSet(.overflow)) }
    
    // jump
    private func jmp(_ value: Word, _ address: Word) { regs.pc = value }
    
    // subroutines
    private func jsr(_ value: Word, _ address: Word) { stack.pushWord(data: regs.pc &- 1, sp: &regs.sp); regs.pc = address }
    private func rts(_ value: Word, _ address: Word) { regs.pc = stack.popWord(sp: &regs.sp) &+ 1 }
    
    // interuptions
    private func rti(_ value: Word, _ address: Word) {
        regs.p &= stack.popByte(sp: &regs.sp) | Flag.alwaysOne.rawValue
        regs.pc = stack.popWord(sp: &regs.sp)
    }
    
    private func brk(_ value: Word, _ address: Word) {
        regs.p.set(.alwaysOne | .breaks)
        stack.pushWord(data: regs.pc &+ 1, sp: &regs.sp) // TODO: make sure pc is handled correctly
        stack.pushByte(data: regs.p.value, sp: &regs.sp)
        regs.pc = memory.readWord(at: InterruptAddress.nmi.rawValue)
    }
    
    // stack
    private func pha(_ value: Word, _ address: Word) { stack.pushByte(data: regs.a, sp: &regs.sp) }
    private func php(_ value: Word, _ address: Word) { stack.pushByte(data: regs.p.value | (.alwaysOne | .breaks), sp: &regs.sp) }
    private func pla(_ value: Word, _ address: Word) { regs.a = stack.popByte(sp: &regs.sp); regs.p.updateFor(regs.a) }
    private func plp(_ value: Word, _ address: Word) { regs.p &= stack.popByte(sp: &regs.sp) & ~Flag.breaks.rawValue | Flag.alwaysOne.rawValue }
    
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
