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

class NintendoEntertainmentSystem: GuardStatus, BusDelegate {
    let screenWidth: UInt16 = 256
    let screenHeight: UInt16 = 240

    private let cpu: CoreProcessingUnit
    private let ppu = PictureProcessingUnit()
    private let apu = AudioProcessingUnit()
    private let ram = RandomAccessMemory()
    private let controller1 = Controller(.primary)
    private let controller2 = Controller(.secondary)
    private let cartridge: Cartridge
    private let bus = Bus()
    private let frequency: Double

    private var deficitCycles: Int64 = 0

    var status: String {
        return """
        \(self.cpu.status)
        \(self.ppu.status)
        \(self.apu.status)
        \(self.cartridge.status)
        \(self.controller1.status)
        """
    }

    init(load game: Cartridge) {
        self.cpu = CoreProcessingUnit(using: self.bus)
        self.cartridge = game
        self.frequency = self.cpu.frequency * 1000000   // MHz * 1e+6 == Hz
        self.bus.delegate = self
        self.cpu.requestInterrupt(type: .reset)
    }

    func reset() {
        // reset mapper
        // reset ram
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

        for _ in 0..<cpuCycle * 3 {
            self.ppu.step()
        }

        self.apu.step()

        return cpuCycle
    }

    // TODO: what to do when the emulation is running behind
    func run(for deltaTime: Double) {
        var cycles: Int64 = Int64(self.frequency * deltaTime) + self.deficitCycles

        while cycles > 0 {
            cycles -= Int64(self.step())
        }

        self.deficitCycles = cycles
    }

    func bus(bus: Bus, didSendReadSignalAt address: Word) -> Byte {
        return self.getComponent(at: address).busRead(at: address)
    }

    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte) {
        self.getComponent(at: address).busWrite(data, at: address)
    }

    private func getComponent(at address: Word) -> BusConnectedComponent {
        switch address {
        case 0x0000..<0x2000: return self.ram
        case 0x4016: return self.controller1
        case 0x4017: return self.controller2
        case 0x6000...0xFFFF: return self.cartridge
        default: fatalError("Not implemented or invalid read/write at 0x\(address.hex())")
        }
    }
}
