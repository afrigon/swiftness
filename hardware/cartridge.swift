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

enum ScreenMirroring {
    case vertical, horizontal, quad
}

enum CartridgeRegion {
    case prg, chr, sram
}

class Cartridge: GuardStatus, BusConnectedComponent, MapperDelegate {
    private let mirroring: ScreenMirroring
    private let battery: Bool
    private let mapperType: MapperType
    private var mapper: Mapper!

    private var programRom: [Byte]
    private var characterRom: [Byte]
    private var saveRam = [Byte](repeating: 0x00, count: 0x2000)
    // should probably be assigned only when supported by the mapper ?

    var status: String {
        return """
        |-------- ROM --------|
         PRG:  \(self.programRom.count / 1024)KB   CHR: \(self.characterRom.count / 1024)KB
         SRAM: \(self.saveRam.count / 1024)KB   Battery: \(self.battery)
         Mirroring:  \(String(describing: self.mirroring).capitalized)
         Mapper:     \(String(describing: self.mapperType).uppercased())
        """
    }

    init(prg: [Byte], chr: [Byte], mapperType: MapperType, mirroring: ScreenMirroring, battery: Bool) {
        self.programRom = prg
        self.characterRom = chr
        self.mirroring = mirroring
        self.battery = battery
        self.mapperType = mapperType
        self.mapper = MapperFactory.create(mapperType, withDelegate: self)
    }

    private func validate(_ region: CartridgeRegion, contains address: Word) -> Bool {
        switch region {
        case .prg: return (0..<self.programRom.count).contains(Int(address))
        case .chr: return (0..<self.characterRom.count).contains(Int(address))
        case .sram: return (0..<self.saveRam.count).contains(Int(address))
        }
    }

    // actions from the bus delivered to the mapper
    func busRead(at address: Word) -> Byte {
        return self.mapper.busRead(at: address)
    }

    func busWrite(_ data: Byte, at address: Word) {
        self.mapper.busWrite(data, at: address)
    }

    func programBankCount(for mapper: Mapper) -> UInt8 {
        return UInt8(UInt32(self.programRom.count) / 0x4000)    // Assuming 0x4000 sized banks
    }

    // actions from the mapper
    func mapper(mapper: Mapper, didReadAt address: Word, of region: CartridgeRegion) -> Byte {
        guard self.validate(region, contains: address) else {
            print("Illegal rom read at: 0x\(address.hex()) on region \(String(describing: region).uppercased())")
            return 0x00
        }

        switch region {
        case .prg: return self.programRom[address]
        case .chr: return self.characterRom[address]
        case .sram: return self.saveRam[address]
        }
    }

    func mapper(mapper: Mapper, didWriteAt address: Word, of region: CartridgeRegion, data: Byte) {
        guard self.validate(region, contains: address) else {
            print("Illegal rom write at: 0x\(address.hex()) on region \(String(describing: region).uppercased())")
            return
        }

        switch region {
        case .prg: self.programRom[address] = data
        case .chr: self.characterRom[address] = data
        case .sram: self.saveRam[address] = data
        }
    }
}
