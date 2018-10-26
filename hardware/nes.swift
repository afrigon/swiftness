//
//  Created by Alexandre Frigon on 2018-10-24.
//  Copyright © 2018 Frigstudio. All rights reserved.
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
