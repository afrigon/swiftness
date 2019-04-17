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

enum ScreenMirroring: Int {
    case horizontal = 0, vertical = 1, quad = 2

    private static let lookupTable: [[Word]] = [
        [0, 0, 1, 1],
        [0, 1, 0, 1],
        [0, 1, 2, 3]
    ]

    func translate(_ address: Word) -> Word {
        let address = (address - 0x2000) % 0x1000
        let tableIndex = address / 0x0400
        let offset = address % 0x0400
        return 0x2000 + ScreenMirroring.lookupTable[self.rawValue][tableIndex] * 0x0400 + offset
    }
}

enum CartridgeRegion {
    case prg, chr, sram
}

class Cartridge: BusConnectedComponent, MapperDelegate {
    let mirroring: ScreenMirroring // should be private (required access from debugger)
    let battery: Bool // should be private (required access from debugger)
    let mapperType: MapperType // should be private (required access from debugger)
    private var mapper: Mapper!

    var programRom: [Byte] // should be private (required access from debugger)
    var characterRom: [Byte] // should be private (required access from debugger)
    private var saveRam = [Byte](repeating: 0x00, count: 0x2000) // should probably be assigned only when supported by the mapper ?

    init(prg: [Byte], chr: [Byte], mapperType: MapperType, mirroring: ScreenMirroring, battery: Bool) {
        self.programRom = prg
        self.characterRom = chr
        self.mirroring = mirroring
        self.battery = battery
        self.mapperType = mapperType
        self.mapper = MapperFactory.create(mapperType, withDelegate: self)
    }

    private func validate(_ region: CartridgeRegion, contains address: DWord) -> Bool {
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
    func mapper(mapper: Mapper, didReadAt address: DWord, of region: CartridgeRegion) -> Byte {
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
        guard self.validate(region, contains: DWord(address)) else {
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
