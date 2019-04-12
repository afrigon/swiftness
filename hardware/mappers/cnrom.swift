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

class CNROM: Mapper {
    weak var delegate: MapperDelegate!

    private let chrBankSize: Word = 0x2000
    private let prgBankSize: Word = 0x4000

    private var chrIndex: Word = 0
    private var prgMirrored: Bool = false   // A 16KB PRG ROM will be mirrored at 0xC000

    required init(_ delegate: MapperDelegate) {
        self.delegate = delegate
        self.prgMirrored = self.delegate.programBankCount(for: self) == 1
    }

    func busRead(at address: Word) -> Byte {
        switch address {
        case 0..<0x2000:
            let address: DWord = DWord(self.chrIndex * self.chrBankSize + address)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .chr)
        case 0x6000..<0x8000:
            let address: DWord = DWord(address - 0x6000)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .sram)
        case 0x8000..<0xC000:
            let address: DWord = DWord(address - 0x8000)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .prg)
        case 0xC000...0xFFFF:
            let address: DWord = DWord(address - 0xC000)
                + DWord(self.prgBankSize * (self.prgMirrored ? 0 : 1))
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .prg)
        default:
            print("CNROM mapper invalid read at 0x\(address.hex())")
            return 0
        }
    }

    func busWrite(_ data: Byte, at address: Word) {
        switch address {
        case 0..<0x2000:
            let address = Word(self.chrIndex * self.chrBankSize + address)
            self.delegate.mapper(mapper: self, didWriteAt: address, of: .chr, data: data)
        case 0x8000...0xFFFF: self.chrIndex = Word(data & 0b11)
        default: print("CNROM mapper invalid write at 0x\(address.hex())")
        }
    }
}
