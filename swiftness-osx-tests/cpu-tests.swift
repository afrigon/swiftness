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

    func test_and() {
        let cpu = self.generateCPU(a: 0b11101111)
        let expected = self.generateRegs(a: 0b10001001, flags: 0b10100000)
        cpu.process(opcode: 0x29, operand: Operand(value: 0b10011001, address: 0))
        self.assertRegister(equal: expected, with: cpu.registers)
    }
}
