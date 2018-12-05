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

class Breakpoint {
    var enabled: Bool = true
    var address: Word?
    var cycles: UInt64?

    init(address: Word) { self.address = address }
    init(cycles: UInt64) { self.cycles = cycles }
}

protocol DebuggerDelegate: AnyObject {
    func debugger(debugger: Debugger, didDumpMemory dump: [String], pc: Int)
}

class Debugger {
    private weak var _delegate: DebuggerDelegate?
    var delegate: DebuggerDelegate? {
        get { return self._delegate }
        set {
            self._delegate = newValue
            self.dumpMemory()
        }
    }
    var breakpoints = [Breakpoint]()

    private var nes: NintendoEntertainmentSystem!
    private var running: Bool = false

    init(nes: NintendoEntertainmentSystem) {
        self.nes = nes
    }

    static func attach(conductor: Conductor) -> Debugger {
        return conductor.attach()
    }

    func loopClosure(_ deltaTime: Double) {
        var cycles: Int64 = Int64(self.nes.frequency * deltaTime) + self.nes.deficitCycles

        guard self.running else {
            return
        }

        while cycles > 0 && self.running == true {
            self.checkBreakpoints()
            cycles -= Int64(self.nes.step())
        }

        self.nes.deficitCycles = self.running ? cycles : 0
        if !self.running { self.dumpMemory() }
    }

    func run() {
        self.running = true
    }

    func pause() {
        self.running = false
    }

    func step() {
        self.nes.step()
        self.dumpMemory()
    }

    private func checkBreakpoints() {
        for breakpoint in self.breakpoints {
            if !breakpoint.enabled { continue }

            if let address = breakpoint.address {
                self.running = self.nes.cpuRegisters.pc == address
            }

            if let cycles = breakpoint.cycles {
                self.running = self.nes.cpuCycle >= cycles
            }
        }
    }

    private func dumpMemory() {
        guard let delegate = self._delegate else {
            return
        }

        var dump = [String]()
        var pc: DWord = 0
        var dumpIndex: Int = 0

        repeat {
            let prepc = Word(pc)
            let opcode = self.nes.bus.readByte(at: Word(pc))
            let (name, addressingMode) = self.nes.opcodeInfo(for: opcode)

            if self.nes.cpuRegisters.pc == pc { dumpIndex = dump.count }
            pc++

            var instruction: String = "\(name) "
            var operand: String = ""

            switch addressingMode {
            case .zeroPage(let alteration):
                let value = self.nes.bus.readByte(at: Word(pc)).hex()
                instruction += "$\(value)"
                instruction += alteration == .none ? "" : ",\(String(describing: alteration))"
                operand += value
                pc++
            case .absolute(let alteration):
                let lowByte = self.nes.bus.readByte(at: Word(pc))
                let highByte = self.nes.bus.readByte(at: Word(pc) &+ 1)
                instruction += "$\(highByte.hex())\(lowByte.hex())"
                instruction += alteration == .none ? "" : ",\(String(describing: alteration))"
                operand += "\(lowByte.hex())\(highByte.hex())"
                pc += 2
            case .relative:
                let value = self.nes.bus.readByte(at: Word(pc))
                let offset = (value.isSignBitOn() ? Word(128 - value & 0b01111111) : value.asWord() & 0b01111111)
                instruction += "\(value.isSignBitOn() ? "-" : "+")$\(offset)"
                pc++

                var address = Word(pc)
                if value.isSignBitOn() {
                    address = address &- offset
                } else {
                    address =  address &+ offset
                }
                instruction += " ($\(address.hex()))"

                operand += value.hex()
            case .indirect(let alteration):
                // TODO: stuff
                pc += alteration == .none ? 2 : 1
            case .immediate:
                let value = self.nes.bus.readByte(at: Word(pc)).hex()
                instruction += "#$\(value)"
                operand += value
                pc++
            case .accumulator: instruction += "a"
            case .implied: break
            }

            let value = "\(opcode.hex())\(operand)".padding(toLength: 6, withPad: " ", startingAt: 0)
            dump.append("\(prepc.hex()) : \(value)\t\t\(instruction)")
        } while pc <= 0xFFFF

        delegate.debugger(debugger: self, didDumpMemory: dump, pc: dumpIndex)
    }
}
