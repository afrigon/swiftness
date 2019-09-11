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

public enum Mirroring: Int {
    case horizontal = 0, vertical = 1, quad = 2, oneScreenLow = 3, oneScreenHigh = 4

    private static let lookupTable: [[Word]] = [
        [0, 0, 1, 1],
        [0, 1, 0, 1],
        [0, 1, 2, 3],
        [0, 0, 0, 0],
        [1, 1, 1, 1]
    ]

    func translate(_ address: Word) -> Word {
        let address = (address - 0x2000) % 0x1000
        let tableIndex = address / 0x0400
        let offset = address % 0x0400
        return 0x2000 + Mirroring.lookupTable[self.rawValue][tableIndex] * 0x0400 + offset
    }
}

public enum CartridgeRegion { case prg, chr, sram }

public class Cartridge: BusConnectedComponent, MapperDelegate {
    let mirroringPointer: UnsafePointer<Mirroring>
    private var mirroring: Mirroring
    private let mapperType: MapperType
    private var mapper: Mapper!

    private var programRom: [Byte]
    private var characterRom: [Byte]
    public var saveRam: [UInt8]! = nil
    public var saveRamSize: Int { return 0x2000 }

    private var _checksum: String
    public var checksum: String { return self._checksum }

    init(prg: [Byte], chr: [Byte], mapperType: MapperType, mirroring: Mirroring, checksum: String) {
        self.programRom = prg
        self.characterRom = chr
        self.mirroring = mirroring
        self.mirroringPointer = UnsafePointer<Mirroring>(&self.mirroring)
        self.mapperType = mapperType
        self._checksum = checksum
        self.mapper = MapperFactory.create(mapperType, withDelegate: self)
    }

    private func validate(_ region: CartridgeRegion, contains address: DWord) -> Bool {
        switch region {
        case .prg: return (0..<self.programRom.count).contains(Int(address))
        case .chr: return (0..<self.characterRom.count).contains(Int(address))
        case .sram: return (0..<self.saveRam.count).contains(Int(address))
        }
    }

    func busRead(at address: Word) -> Byte {
        return self.mapper.busRead(at: address)
    }

    func busWrite(_ data: Byte, at address: Word) {
        self.mapper.busWrite(data, at: address)
    }

    func mapper(mapper: Mapper, didChangeMirroring mirroring: Mirroring) {
        self.mirroring = mirroring
    }


    func prgBankCount(mapper: Mapper, ofsize size: Word) -> Byte {
        return Byte(DWord(self.programRom.count) / DWord(size))
    }

    func chrBankCount(mapper: Mapper, ofsize size: Word) -> Byte {
        return Byte(DWord(self.characterRom.count) / DWord(size))
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

    func mapper(mapper: Mapper, didWriteAt address: DWord, of region: CartridgeRegion, data: Byte) {
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
