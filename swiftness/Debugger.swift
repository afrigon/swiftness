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

class Breakpoint {
    var enabled: Bool = true
    var address: Word

    init(address: Word) { self.address = address }
}

class Breakpoints {
    private var breakpoints = [Word: Breakpoint]()

    var count: Int { return self.breakpoints.count }
    var raw: [Word: Breakpoint] { return self.breakpoints }
    var enabled: Bool = true

    func append(_ newElement: Breakpoint) {
        self.breakpoints[newElement.address] = newElement
    }

    subscript(address: Word) -> Breakpoint? {
        return self.breakpoints[address]
    }

    func find(at address: Word) -> Bool {
        return self.breakpoints[address] != nil
    }

    func toggle(at address: Word) {
        guard self.find(at: address) else { return }
        self.breakpoints[address]!.enabled = !self.breakpoints[address]!.enabled
    }

    func remove(at address: Word) {
        guard let index = self.breakpoints.index(forKey: address) else { return }
        self.breakpoints.remove(at: index)
    }

    func removeAll() {
        self.breakpoints.removeAll()
    }
}

protocol DebuggerDelegate: AnyObject {
    func debugger(debugger: Debugger, didDumpMemory memoryDump: MemoryDump, programCounter: Word)
    func debugger(debugger: Debugger, didUpdate registers: RegisterSet)
    func toggleBreakpoints(_ sender: AnyObject)
    func run(_ sender: AnyObject)
    func step(_ sender: AnyObject)
    func stepLine(_ sender: AnyObject)
    func stepFrame(_ sender: AnyObject)
    func refresh(_ sender: AnyObject)
}

class DebuggerInfo {
    let lineNumber: Word
    let addressPointer: Word
    var opcode: Byte = 0
    var operand: String = ""
    var textOperand: String = ""
    var name: String = ""
    var addressingMode: AddressingMode = .implied

    var raw: String {
        return "\(self.opcode.hex())\(self.operand)".padding(toLength: 6, withPad: " ", startingAt: 0)
    }

    var string: String {
        return "\(self.raw)\t\t\(self.name) \(self.textOperand)"
    }

    init(atLine lineNumber: Word, addressPointer: DWord) {
        self.lineNumber = lineNumber
        self.addressPointer = Word(addressPointer)
    }
}

class MemoryDump {
    private var dump = [DebuggerInfo]()
    private var lineSymbols = [Word: Int]()
    private var addressSymbols = [Word: Int]()

    var count: Int { return self.dump.count }

    func append(_ info: DebuggerInfo) {
        self.lineSymbols[info.lineNumber] = self.dump.count
        self.addressSymbols[info.addressPointer] = self.dump.count
        self.dump.append(info)
    }

    func removeAll() {
        self.dump.removeAll()
        self.lineSymbols.removeAll()
        self.addressSymbols.removeAll()
    }

    func getInfo(forLine line: Word) -> DebuggerInfo? {
        guard let index = self.lineSymbols[line] else { return nil }
        return self.dump[index]
    }

    func getInfo(forAddress address: Word) -> DebuggerInfo? {
        guard let index = self.addressSymbols[address] else { return nil }
        return self.dump[index]
    }

    func convert(lineToAddress line: Word) -> Word? {
        guard let info = self.getInfo(forLine: line) else { return nil }
        return info.addressPointer
    }

    func convert(addressToLine address: Word) -> Word? {
        guard let info = self.getInfo(forAddress: address) else { return nil }
        return info.lineNumber
    }

    subscript(i: Int) -> DebuggerInfo? {
        get { return self.getInfo(forLine: Word(i)) }
    }
}

class Debugger {
    private weak var _delegate: DebuggerDelegate?
    var delegate: DebuggerDelegate? {
        get { return self._delegate }
        set {
            self._delegate = newValue
            self._delegate!.debugger(debugger: self, didDumpMemory: self.memoryDump, programCounter: self.nes.cpuRegisters.pc)
        }
    }

    private var _running: Bool = false
    var running: Bool { return self._running }
    var totalCycles: UInt64 { return self.nes.cpuCycle }
    var cpuRegisters: RegisterSet { return self.nes.cpuRegisters }
    var cartridge: Cartridge { return self.nes.cartridge }
    var ppu: PictureProcessingUnit { return self.nes.ppu }

    private var nes: NintendoEntertainmentSystem!

    var breakpoints = Breakpoints()
    let memoryDump = MemoryDump()

    init(nes: NintendoEntertainmentSystem) {
        self.nes = nes
        self.disassembleMemory()
    }

    static func attach(conductor: Conductor) -> Debugger {
        return conductor.attach()
    }

    func readMemory(at address: Word) -> Byte {
        return self.nes.bus.readByte(at: address)
    }

    func loopClosure(_ deltaTime: Double) {
        var cycles: Int64 = Int64(self.nes.frequency * deltaTime) + self.nes.deficitCycles

        guard self._running else {
            return
        }

        cycles -= Int64(self.nes.step())
        while cycles > 0 && self._running == true {
            self._running = !self.shouldBreak()
            if !self._running { break }
            cycles -= Int64(self.nes.step())
        }

        self.nes.deficitCycles = self._running ? cycles : 0
        if !self._running { self.refresh() }
    }

    func run() {
        self._running = true
    }

    func pause() {
        self._running = false
    }

    func step() -> UInt8 {
        defer { self.updateMemoryDump() }
        return self.nes.step()
    }

    func stepLine() -> UInt64 {
        defer { self.updateMemoryDump() }
        return self.nes.stepLine()
    }

    func stepFrame() -> UInt64 {
        defer { self.updateMemoryDump() }
        return self.nes.stepFrame()
    }

    func refresh() {
        guard let delegate = self._delegate else {
            return
        }

        self.disassembleMemory()
        delegate.debugger(debugger: self, didDumpMemory: self.memoryDump, programCounter: self.nes.cpuRegisters.pc)
    }

    private func shouldBreak() -> Bool {
        guard self.breakpoints.enabled else {
            return false
        }

        for (_, breakpoint) in self.breakpoints.raw {
            guard breakpoint.enabled else { continue }

            if self.nes.cpuRegisters.pc == breakpoint.address { return true }
        }
        return false
    }

    private func disassembleMemory() {
        self.memoryDump.removeAll()
        var lineNumber: Word = 0
        var localProgramCounter: DWord = 0

        repeat {
            // dirty fix to avoid increasing vram pointer
            if (0x2000..<0x4000).contains(localProgramCounter) {
                localProgramCounter = 0x4000
            }

            let info: DebuggerInfo = DebuggerInfo(atLine: lineNumber, addressPointer: localProgramCounter)
            info.opcode = self.nes.bus.readByte(at: Word(localProgramCounter))

            let (name, addressingMode) = self.nes.opcodeInfo(for: info.opcode)
            info.name = name
            info.addressingMode = addressingMode

            localProgramCounter++

            switch addressingMode {
            case .zeroPage(let alteration):
                let value = self.nes.bus.readByte(at: Word(localProgramCounter)).hex()
                info.textOperand += "$\(value)"
                info.textOperand += alteration == .none ? "" : ",\(String(describing: alteration))"
                info.operand += value
                localProgramCounter++
            case .absolute(let alteration, _):
                let lowByte = self.nes.bus.readByte(at: Word(localProgramCounter))
                let highByte = self.nes.bus.readByte(at: Word(localProgramCounter) &+ 1)
                info.textOperand += "$\(highByte.hex())\(lowByte.hex())"
                info.textOperand += alteration == .none ? "" : ",\(String(describing: alteration))"
                info.operand += "\(lowByte.hex())\(highByte.hex())"
                localProgramCounter += 2
            case .relative:
                let value = self.nes.bus.readByte(at: Word(localProgramCounter))
                let offset = (value.isSignBitOn() ? Word(128 - value & 0b01111111) : value.asWord() & 0b01111111)
                info.textOperand += "\(value.isSignBitOn() ? "-" : "+")$\(offset)"
                localProgramCounter++

                var address = Word(localProgramCounter)
                if value.isSignBitOn() {
                    address = address &- offset
                } else {
                    address = address &+ offset
                }
                info.textOperand += " ($\(address.hex()))"

                info.operand += value.hex()
            case .indirect(let alteration):
                let lowByte = self.nes.bus.readByte(at: Word(localProgramCounter))
                info.operand += "\(lowByte.hex())"

                if alteration == .none {
                    let highByte = self.nes.bus.readByte(at: Word(localProgramCounter) &+ 1)
                    info.operand += "\(highByte.hex())"
                }

                info.textOperand += "indirect"
                localProgramCounter += alteration == .none ? 2 : 1
            case .immediate:
                let value = self.nes.bus.readByte(at: Word(localProgramCounter)).hex()
                info.textOperand += "#$\(value)"
                info.operand += value
                localProgramCounter++
            case .accumulator: info.textOperand += "a"
            case .implied: break
            }

            if info.opcode == 0x60 { info.textOperand = "--------------------" }

            lineNumber++
            self.memoryDump.append(info)
        } while (localProgramCounter <= 0xFFFF)
    }

    private func updateMemoryDump() {
        guard let delegate = self._delegate else {
            return
        }

        // should probably refresh stack and stuff

        delegate.debugger(debugger: self, didUpdate: self.nes.cpuRegisters)
    }
}
