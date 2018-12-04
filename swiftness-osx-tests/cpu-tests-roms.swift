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

class CoreProcessingUnitTestsRoms: XCTestCase, BusDelegate {
    private var cpu: CoreProcessingUnit!
    private var program = [Byte]()
    private let bus = Bus()

    override func setUp() {
        self.cpu = CoreProcessingUnit(using: self.bus)
        self.bus.delegate = self
    }

    func testInstructions() {
        let startAddress: Word = 0x0400
        let successAddress: Word = 0x33dc

        // load program
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "cpu-instructions-tests", ofType: "bin")!
        self.program = NesFile.loadRaw(path: path)

        // jump to start address
        self.cpu.process(opcode: 0x4C, operand: Operand(value: 0, address: startAddress, additionalCycles: 0))

        var lastInstructions = [Word](repeating: 0, count: 50)
        while lastInstructions.last! != self.cpu.registers.pc {
            lastInstructions.append(self.cpu.registers.pc)
            lastInstructions.removeFirst()

            self.cpu.step()
        }

        XCTAssert(self.cpu.registers.pc == successAddress, """
        The cpu got trapped at 0x\(lastInstructions.last!.hex())
        Trace:
            \(lastInstructions.reduce("", { (acc, n) -> String in return "\(acc)0x\(n.hex())\n\t" }))
        """)
    }

    func bus(bus: Bus, didSendReadSignalAt address: Word) -> Byte {
        return self.program[address]
    }

    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte) {
        self.program[address] = data
    }

    func bus(bus: Bus, shouldTriggerInterrupt type: InterruptType) {}
    func bus(bus: Bus, shouldRenderFrame frameBuffer: FrameBuffer) {}
    func bus(bus: Bus, didSendReadSignalAt address: Word, of component: Component) -> Byte { return 0 }
    func bus(bus: Bus, didSendWriteSignalAt address: Word, of component: Component, data: Byte) {}
}
