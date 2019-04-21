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

import Foundation

class NesFile {
    private struct Header {
        let prgSize: Byte   // unit: 16384 bytes
        let chrSize: Byte   // unit: 8192 bytes
        let control1: Byte
        let control2: Byte
        let ramSize: Byte   // unit: 8192 bytes     not handled yet
        let padding = [Byte](repeating: 0x00, count: 7)

        init?(_ values: [Byte]) {
            guard values.count == Header.size && NesFile.validateMagic(a: values[0], b: values[1], c: values[2], d: values[3]) else { return nil }

            self.prgSize = values[4]
            self.chrSize = values[5]
            self.control1 = values[6]
            self.control2 = values[7]
            self.ramSize = values[8]
        }

        static var size: Int = 16
    }

    static func validateMagic(a: UInt8, b: UInt8, c: UInt8, d: UInt8) -> Bool {
        return UInt32(a) << 24 | UInt32(b) << 16 | UInt32(c) << 8 | UInt32(d) == 0x4E45531A // NES^
    }

    static func validateMagic(_ data: Data) -> Bool {
        return data.count >= 4 && NesFile.validateMagic(a: data[0], b: data[1], c: data[2], d: data[3])
    }

    static func parse(data: NSData) -> Cartridge? {
        var headerData = [UInt8](repeating:0, count: Header.size)
        data.getBytes(&headerData, length: Header.size)
        guard let header = Header(headerData) else {
            return nil
        }

        let battery = Bool(header.control1 & 0b10)
        let mirroring: ScreenMirroring = !Bool(header.control1 & 0b1000)
            ? (Bool(header.control1 & 1)
                ? .vertical
                : .horizontal)
            : .quad
        let mapperNumber = header.control1 >> 4 | header.control2 & 0xF0
        guard let mapperType = MapperType(rawValue: mapperNumber) else {
            fatalError("Mapper (\(mapperNumber)) is not implemented")
        }

        let trainerSize = Bool(header.control1 & 0b100) ? 512 : 0
        let prgSize = Int(header.prgSize) * 16384
        let prgRange = NSRange(location: Header.size + trainerSize, length: prgSize)
        var prg = [Byte](repeating: 0x00, count: prgSize)
        data.getBytes(&prg, range: prgRange)

        let chrSize = Bool(header.chrSize) ? Int(header.chrSize) * 8192 : 8192
        var chr = [Byte](repeating: 0x00, count: chrSize)
        if Bool(header.chrSize) {
            let chrRange: NSRange = NSMakeRange(Header.size + trainerSize + prgSize, chrSize)
            data.getBytes(&chr, range: chrRange)
        }

        return Cartridge(prg: prg, chr: chr, mapperType: mapperType, mirroring: mirroring, battery: battery)
    }

    static func raw(path: String) -> [Byte] {
        guard let data: NSData = NSData(contentsOfFile: path) else {
            fatalError("Could not open file at: \(path)")
        }

        var program = [Byte](repeating: 0x00, count: data.length)
        data.getBytes(&program, range: NSRange(location: 0, length: data.length))

        return program
    }
}
