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

class UNROM: Mapper {
    weak var delegate: MapperDelegate!

    private let prgBankSize: Word = 0x4000
    private var prgIndex0: Byte = 0
    private var prgIndex1: Byte = 0

    required init(_ delegate: MapperDelegate) {
        self.delegate = delegate
        self.prgIndex1 = self.delegate.programBankCount(for: self) - 1
    }

    func busRead(at address: Word) -> Byte {
        switch address {
        case 0..<0x2000:
            let address: DWord = DWord(address)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .chr)
        case 0x6000..<0x8000:
            let address: DWord = DWord(address - 0x6000)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .sram)
        case 0x8000..<0xC000:
            let address: DWord = DWord(address - 0x8000) + DWord(self.prgIndex0) * DWord(self.prgBankSize)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .prg)
        case 0xC000...0xFFFF:
            let address: DWord = DWord(address - 0xC000) + DWord(self.prgIndex1) * DWord(self.prgBankSize)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .prg)
        default:
            print("UNROM mapper invalid read at 0x\(address.hex())")
            return 0
        }
    }

    func busWrite(_ data: Byte, at address: Word) {
        switch address {
        case 0..<0x2000:
            self.delegate.mapper(mapper: self, didWriteAt: address, of: .chr, data: data)
        case 0x6000..<0x8000:
            self.delegate.mapper(mapper: self, didWriteAt: address - 0x6000, of: .sram, data: data)
        case 0x8000...0xFFFF:
            self.prgIndex0 = data % self.delegate.programBankCount(for: self)
        default: print("UNROM mapper invalid write at 0x\(address.hex())")
        }
    }
}
