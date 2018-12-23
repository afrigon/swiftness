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

enum Component {
    case cpu, ppu, apu, controller1, controller2, cartridge
}

class NintendoEntertainmentSystem: BusDelegate {
    static let screenWidth: Int = 256
    static let screenHeight: Int = 240

    private weak var delegate: EmulatorDelegate!
    private let cpu: CoreProcessingUnit
    let ppu: PictureProcessingUnit // private
    private let apu = AudioProcessingUnit()
    private let ram = RandomAccessMemory()
    private let controller1 = Controller(.primary)
    private let controller2 = Controller(.secondary)
    let cartridge: Cartridge // private
    let bus = Bus()

    var deficitCycles: Int64 = 0
    var frequency: Double { return self.cpu.frequency }

    var cpuCycle: UInt64 { return self.cpu.totalCycles }
    var cpuRegisters: RegisterSet { return self.cpu.registers }
    var ppuFrame: Int64 { return self.ppu.frame }
    var ppuScanline: UInt16 { return self.ppu.scanline }
    var ppuCycle: UInt16 { return self.ppu.cycle }

    func opcodeInfo(for opcode: Byte) -> (String, AddressingMode) {
        return self.cpu.opcodeInfo(for: opcode)
    }

    var mirroringMode: ScreenMirroring {
        return self.cartridge.mirroring
    }

    init(load game: Cartridge, hostedBy delegate: EmulatorDelegate) {
        self.delegate = delegate
        self.cpu = CoreProcessingUnit(using: self.bus)
        self.ppu = PictureProcessingUnit(using: self.bus)
        self.cartridge = game
        self.bus.delegate = self
        self.reset()
    }

    func reset() {
        // reset mapper
        // reset ram
        self.ppu.reset()
        self.cpu.requestInterrupt(type: .reset)
    }

    func setInputs(to value: Byte, for player: Controller.Player = .primary) {
        switch player {
        case .primary: self.controller1.buttons = value
        case .secondary: self.controller2.buttons = value
        }
    }

    @discardableResult
    func step() -> UInt8 {
        let cpuCycle: UInt8 = self.cpu.step()
        for _ in 0..<cpuCycle * 3 { self.ppu.step() }
        self.apu.step()

        return cpuCycle
    }

    // TODO: what to do when the emulation is running behind
    func run(for deltaTime: Double) {
        var cycles: Int64 = Int64(self.cpu.frequency * deltaTime) + self.deficitCycles

        while cycles > 0 {
            cycles -= Int64(self.step())
        }

        self.deficitCycles = cycles
    }

    func stepLine(_ count: UInt16 = 1) -> UInt64 {
        var cyclesCount: UInt64 = 0
        let endLine = (self.ppu.scanline + count) % self.ppu.scanlinePerFrame
        while self.ppu.scanline < endLine { cyclesCount += UInt64(self.step()) }
        return cyclesCount
    }

    func stepFrame(_ count: Int64 = 1) -> UInt64 {
        var cyclesCount: UInt64 = 0
        let endFrame = self.ppu.frame + count
        while self.ppu.frame < endFrame { cyclesCount += UInt64(self.step()) }
        return cyclesCount
    }

    func bus(bus: Bus, shouldTriggerInterrupt type: InterruptType) {
        self.cpu.requestInterrupt(type: type)
    }

    func bus(bus: Bus, shouldRenderFrame frameBuffer: FrameBuffer) {
        self.delegate!.emulator(nes: self, shouldRenderFrame: frameBuffer)
    }

    func bus(bus: Bus, didBlockFor cycles: UInt16) {
        self.cpu.stallCycles += cycles
    }

    func bus(bus: Bus, didSendReadSignalAt address: Word) -> Byte {
        guard let component = self.getComponent(at: address) else { return 0 }
        return self.bus(bus: bus, didSendReadSignalAt: address, of: component)
    }

    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte) {
        guard let component = self.getComponent(at: address) else { return }
        self.bus(bus: bus, didSendWriteSignalAt: address, of: component, data: data)
    }

    func bus(bus: Bus, didSendReadSignalAt address: Word, of component: Component) -> Byte {
        switch component {
        case .cpu: return self.ram.busRead(at: address)
        case .ppu: return self.ppu.busRead(at: address)
        case .apu: return self.apu.busRead(at: address)
        case .controller1: return self.controller1.busRead(at: address)
        case .controller2: return self.controller2.busRead(at: address)
        case .cartridge: return self.cartridge.busRead(at: address)
        }
    }

    func bus(bus: Bus, didSendWriteSignalAt address: Word, of component: Component, data: Byte) {
        switch component {
        case .cpu: self.ram.busWrite(data, at: address)
        case .ppu: self.ppu.busWrite(data, at: address)
        case .apu: self.apu.busWrite(data, at: address)
        case .controller1: self.controller1.busWrite(data, at: address)
        case .controller2: self.controller2.busWrite(data, at: address)
        case .cartridge: self.cartridge.busWrite(data, at: address)
        }
    }

    private func getComponent(at address: Word) -> Component? {
        switch address {
        case 0x0000..<0x2000: return .cpu
        case 0x2000..<0x4000, 0x4014: return .ppu
        case 0x4000...0x4013, 0x4015: return .apu
        case 0x4016: return .controller1
        case 0x4017: return .controller2
        case 0x6000...0xFFFF: return .cartridge
        default: return nil
        }
    }
}
