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

import XCTest
@testable import swiftness_osx

class CoreProcessingUnitTests: XCTestCase {
    private func generateRegs(a: Byte? = nil, x: Byte? = nil, y: Byte? = nil, flags: Byte = 0) -> RegisterSet {
        return RegisterSet(a: a ?? 0x10, x: x ?? 0x20, y: y ?? 0x30, p: ProcessorStatusRegister(flags | Flag.alwaysOne.rawValue), sp: 0xFD, pc: 0x1234)
    }
    
    private func generateCPU(a: Byte? = nil, x: Byte? = nil, y: Byte? = nil, flags: Byte = 0) -> CoreProcessingUnit {
        let regs = self.generateRegs(a: a, x: x, y: y, flags: flags)
        let cpu = CoreProcessingUnit(using: Bus.testsInstance(), with: regs)
        return cpu
    }
    
    func assertRegister(equal expected: RegisterSet, with before: RegisterSet, _ operation: String = #function) {
        XCTAssert(before.a == expected.a, "Register A dont't match for operation -> \(operation) (\(before.a) != \(expected.a))")
        XCTAssert(before.x == expected.x, "Register X dont't match for operation -> \(operation) (\(before.x) != \(expected.x))")
        XCTAssert(before.y == expected.y, "Register Y dont't match for operation -> \(operation) (\(before.y) != \(expected.y))")
        XCTAssert(before.p == expected.p, "Register P dont't match for operation -> \(operation) (\(before.p) != \(expected.p))")
        XCTAssert(before.sp == expected.sp, "Register SP dont't match for operation -> \(operation) (\(before.sp) != \(expected.sp))")
        XCTAssert(before.pc == expected.pc, "Register PC dont't match for operation -> \(operation) (\(before.pc) != \(expected.pc))")
    }

    func test_nop() {
        let cpu = self.generateCPU()
        let expected = self.generateRegs()
        cpu.process(opcode: 0xEA)
        self.assertRegister(equal: expected, with: cpu.registers)
    }
    
    
    func test_inx() {
        var cpu = self.generateCPU()
        var expected = self.generateRegs(x: 0x21)
        cpu.process(opcode: 0xE8)
        self.assertRegister(equal: expected, with: cpu.registers)
        
        // sets the negative flag
        cpu = self.generateCPU(x: 0b01111111)
        expected = self.generateRegs(x: 0b10000000, flags: Flag.negative.rawValue)
        cpu.process(opcode: 0xE8)
        self.assertRegister(equal: expected, with: cpu.registers)
        
        // sets the zero flag
        cpu = self.generateCPU(x: 0xFF)
        expected = self.generateRegs(x: 0, flags: Flag.zero.rawValue)
        cpu.process(opcode: 0xE8)
        self.assertRegister(equal: expected, with: cpu.registers)
    }
    
    
    func test_iny() {
        var cpu = self.generateCPU()
        var expected = self.generateRegs(y: 0x31)
        cpu.process(opcode: 0xC8)
        self.assertRegister(equal: expected, with: cpu.registers)
        
        // sets the negative flag
        cpu = self.generateCPU(y: 0b01111111)
        expected = self.generateRegs(y: 0b10000000, flags: Flag.negative.rawValue)
        cpu.process(opcode: 0xC8)
        self.assertRegister(equal: expected, with: cpu.registers)
        
        // sets the zero flag
        cpu = self.generateCPU(y: 0xFF)
        expected = self.generateRegs(y: 0, flags: Flag.zero.rawValue)
        cpu.process(opcode: 0xC8)
        self.assertRegister(equal: expected, with: cpu.registers)
    }
    

    func test_dex() {
        var cpu = self.generateCPU()
        var expected = self.generateRegs(x: 0x1F)
        cpu.process(opcode: 0xCA)
        self.assertRegister(equal: expected, with: cpu.registers)
        
        // sets the negative flag
        cpu = self.generateCPU(x: 0)
        expected = self.generateRegs(x: 0xFF, flags: Flag.negative.rawValue)
        cpu.process(opcode: 0xCA)
        self.assertRegister(equal: expected, with: cpu.registers)
        
        // sets the zero flag
        cpu = self.generateCPU(x: 0x1)
        expected = self.generateRegs(x: 0, flags: Flag.zero.rawValue)
        cpu.process(opcode: 0xCA)
        self.assertRegister(equal: expected, with: cpu.registers)
    }

    func test_dey() {
        var cpu = self.generateCPU()
        var expected = self.generateRegs(y: 0x2F)
        cpu.process(opcode: 0x88)
        self.assertRegister(equal: expected, with: cpu.registers)
        
        // sets the negative flag
        cpu = self.generateCPU(y: 0)
        expected = self.generateRegs(y: 0xFF, flags: Flag.negative.rawValue)
        cpu.process(opcode: 0x88)
        self.assertRegister(equal: expected, with: cpu.registers)
        
        // sets the zero flag
        cpu = self.generateCPU(y: 0x1)
        expected = self.generateRegs(y: 0, flags: Flag.zero.rawValue)
        cpu.process(opcode: 0x88)
        self.assertRegister(equal: expected, with: cpu.registers)
    }
//
//    func test_adc() {
//        self.cpu.process(opcode: 0x65, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_sbc() {
//        self.cpu.process(opcode: 0xE5, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_inc() {
//        self.cpu.process(opcode: 0xE6, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_dec() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }

    func test_and() {
        let cpu = self.generateCPU(a: 0b11101111)
        let expected = self.generateRegs(a: 0b10001001, flags: 0b10100000)
        cpu.process(opcode: 0x29, operand: Operand(value: 0b10011001, address: 0))
        self.assertRegister(equal: expected, with: cpu.registers)
    }

//    func test_eor() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_ora() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_bit() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_asl() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_lsr() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_rol() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_ror() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_clc() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_cld() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_cli() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_clv() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_sec() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_sed() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_sei() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_cmp() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_cpx() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_cpy() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_beq() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_bne() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_bmi() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_bpl() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_bcs() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_bcc() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_bvs() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_bvc() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_jmp() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_jsr() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_rts() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_rti() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_brk() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_pha() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_php() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_pla() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_plp() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_lda() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_ldx() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_ldy() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_sta() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_stx() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_sty() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_tax() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_txa() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_tay() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_tya() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_tsx() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_txs() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_asla() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_lsra() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_rola() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
//
//    func test_rora() {
//        self.cpu.process(opcode: 0x00, operand: Operand(value: Word(0), address: Word(0)))
//        let expectedRegisters = RegisterSet(a: Byte(0x10), x: Byte(0x20), y: Byte(0x30), p: ProcessorStatusRegister(0x34), sp: Byte(0xFD), pc: Word(0x1234))
//        self.assertRegister(equal: expectedRegisters)
//    }
}
