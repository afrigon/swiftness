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

    private let prgSize: Word = 0x4000
    private var prgCount: Byte = 0

    private var prgOffsets: [Word] = [0, 0]

    required init(_ delegate: MapperDelegate) {
        self.delegate = delegate
        self.prgCount = self.delegate.prgBankCount(mapper: self, ofsize: self.prgSize)
        self.prgOffsets[1] = Word(self.prgCount - 1) * self.prgSize
    }

    func busRead(at address: Word) -> Byte {
        if address < 0x2000 {
            let address: DWord = DWord(address)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .chr)
        }

        if address >= 0x6000 && address < 0x8000 {
            let address: DWord = DWord(address - 0x6000)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .sram)
        }

        if address >= 0x8000 {
            var address: DWord = DWord(address - 0x8000)
            address = DWord(self.prgOffsets[address / DWord(self.prgSize)]) + address % DWord(self.prgSize)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .prg)
        }

        print("UNROM mapper invalid read at 0x\(address.hex())")
        return 0
    }

    func busWrite(_ data: Byte, at address: Word) {
        if address < 0x2000 {
            return self.delegate.mapper(mapper: self, didWriteAt: DWord(address), of: .chr, data: data)
        }

        if address >= 0x6000 && address < 0x8000 {
            return self.delegate.mapper(mapper: self, didWriteAt: DWord(address - 0x6000), of: .sram, data: data)
        }

        if address >= 0x8000 {
            return self.prgOffsets[0] = Word(data % self.prgCount) * self.prgSize
        }

        print("UNROM mapper invalid write at 0x\(address.hex())")
    }
}
