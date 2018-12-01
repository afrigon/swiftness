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

import Foundation

fileprivate struct Header {
    let filetype: DWord = 0
    let prgSize: Byte = 0   // * (16KB -> 16384)
    let chrSize: Byte = 0   // * (8KB -> 8192)
    let control1: Byte = 0
    let control2: Byte = 0
    let ramSize: Byte = 0   // * (8KB -> 8192)
    let padding = [Byte](repeating: 0x00, count: 7)
    static var size: Int = 16
}

class NesFile {
    static let filetypeValue: DWord = 0x4E45531A    // NES^

    static func load(path: String) -> Cartridge {
        guard let data: NSData = NSData(contentsOfFile: path) else {
            fatalError("Could not open file at: \(path)")
        }

        var header: Header = Header()
        data.getBytes(&header, length: Header.size)
        NesFile.validateFormat(header)

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

    static func loadRaw(path: String) -> [Byte] {
        guard let data: NSData = NSData(contentsOfFile: path) else {
            fatalError("Could not open file at: \(path)")
        }

        var program = [Byte](repeating: 0x00, count: data.length)
        data.getBytes(&program, range: NSRange(location: 0, length: data.length))

        return program
    }

    private static func validateFormat(_ header: Header) {
        guard NesFile.filetypeValue == DWord(bigEndian: header.filetype) else {
            fatalError("File is not .nes format")
        }
    }
}
