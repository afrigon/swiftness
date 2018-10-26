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
    private let apu = PictureProcessingUnit()
    private let ram = RandomAccessMemory()
    private let controller1 = Controller()
    private let controller2 = Controller()
    private let cartridge = Cartridge()
    private let bus = Bus()
    
    var status: String {
        return """
        \(self.cpu.status)
        \(self.ppu.status)
        \(self.apu.status)
        \(self.ram.status)
        \(self.controller1.status)
        \(self.controller2.status)
        \(self.cartridge.status)
        """
    }
    
    init() {
        self.cpu = CoreProcessingUnit(using: self.bus)
        self.bus.delegate = self
    }
    
    func bus(bus: Bus, didSendReadSignalAt address: Word) -> Byte {
        return self.getComponent(at: address).busRead(at: address)
    }
    
    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte) {
        self.getComponent(at: address).busWrite(data, at: address)
    }
    
    func getComponent(at address: Word) -> BusConnectedComponent {
        switch address {
        case 0x0000..<0x2000: return self.ram
        case 0x4016: return self.controller1
        case 0x4017: return self.controller2
        default:
            fatalError("Not implemented or invalid read/write at \(address.hex())")
        }
    }
}
