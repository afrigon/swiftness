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

public class nes: BusDelegate {
    static let screenWidth: Int = 256
    static let screenHeight: Int = 240

    private let cpu: CoreProcessingUnit
    private let ppu: PictureProcessingUnit
    private let apu = AudioProcessingUnit()
    private let ram = RandomAccessMemory()
    private let controller1 = Controller(.primary)
    private let controller2 = Controller(.secondary)
    private let cartridge: Cartridge
    private let bus = Bus()

    private var deficitCycles: Int64 = 0

    public var saveRam: UnsafeBufferPointer<UInt8> {
        return UnsafeBufferPointer(start: &self.cartridge.saveRam,
                                   count: self.cartridge.saveRam.count)
    }
    public var checksum: String { return self.cartridge.checksum }

    public var screenWidth: Int { return nes.screenWidth }
    public var screenHeight: Int { return nes.screenHeight }

    public var mainColor: UInt32 { return self.ppu.mainColor }
    public var needsRender: Bool { return self.ppu.needsRender }
    public var framebuffer: UnsafeBufferPointer<UInt8> { return self.ppu.frameBuffer }

    public init(load rom: Cartridge, saveRam: [UInt8] = []) {
        self.cpu = CoreProcessingUnit(using: self.bus)
        self.ppu = PictureProcessingUnit(using: self.bus, mirroring: rom.mirroringPointer)
        self.cartridge = rom
        self.cartridge.saveRam = saveRam
        self.bus.delegate = self
        self.reset()
    }

    public func reset() {
        // reset mapper
        self.ppu.reset()
        self.cpu.requestInterrupt(type: .reset)
    }

    public func setInputs(to value: UInt8, for player: Controller.Player = .primary) {
        switch player {
        case .primary: self.controller1.buttons = value
        case .secondary: self.controller2.buttons = value
        }
    }

    @discardableResult
    func step() -> UInt8 {
        let cpuCycle: UInt8 = self.cpu.step()

        let ppuCycle = cpuCycle * 3
        for _ in 0..<ppuCycle { self.ppu.step() }

        self.apu.step()

        return cpuCycle
    }

    public func run(for deltaTime: Double) {
        var cycles: Int64 = Int64(self.cpu.frequency * deltaTime) + self.deficitCycles

        while cycles > 0 {
            cycles -= Int64(self.step())
        }

        self.deficitCycles = cycles
    }

    func bus(bus: Bus, shouldTriggerInterrupt type: InterruptType) {
        self.cpu.requestInterrupt(type: type)
    }

    func bus(bus: Bus, didBlockFor cycles: UInt16) {
        self.cpu.stall(for: cycles)
    }

    func bus(bus: Bus, didSendReadSignalAt address: Word, rom: Bool = false) -> Byte {
        if rom { return self.cartridge.busRead(at: address) }
        if address < 0x2000 { return self.ram.busRead(at: address) }
        if address < 0x4000 || address == 0x4014 { return self.ppu.busRead(at: address) }
        if address <= 0x4013 || address == 0x4015 { return self.apu.busRead(at: address) }
        if address == 0x4016 { return self.controller1.busRead(at: address) }
        if address == 0x4017 { return self.controller2.busRead(at: address) }
        if address >= 0x6000 { return self.cartridge.busRead(at: address) }
        return 0
    }

    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte, rom: Bool = false) {
        if rom {
            self.cartridge.busWrite(data, at: address)
        } else if address < 0x2000 {
            self.ram.busWrite(data, at: address)
        } else if address < 0x4000 || address == 0x4014 {
            self.ppu.busWrite(data, at: address)
        } else if address <= 0x4013 || address == 0x4015 {
            self.apu.busWrite(data, at: address)
        } else if address == 0x4016 {
            self.controller1.busWrite(data, at: address)
            self.controller2.busWrite(data, at: address)
        } else if address == 0x4017 {
            self.apu.busWrite(data, at: address)
        } else if address >= 0x6000 {
            self.cartridge.busWrite(data, at: address)
        }
    }
}
