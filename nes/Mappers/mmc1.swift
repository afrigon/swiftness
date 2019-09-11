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

class MMC1: Mapper {
    weak var delegate: MapperDelegate!

    private let prgSize: DWord = 0x4000
    private let chrSize: DWord = 0x1000
    private var prgCount: Byte = 0
    private var chrCount: Byte = 0

    private var prgBankOffsets: [DWord] = [0, 0]
    private var chrBankOffsets: [DWord] = [0, 0]

    private var shiftRegister: Byte = 0b10000
    private var controlRegister: Byte = 0
    private var prgBankRegister: Byte = 0
    private var chrBankRegister0: Byte = 0
    private var chrBankRegister1: Byte = 0

    required init(_ delegate: MapperDelegate) {
        self.delegate = delegate
        self.prgCount = self.delegate.prgBankCount(mapper: self, ofsize: Word(self.prgSize))
        self.chrCount = self.delegate.chrBankCount(mapper: self, ofsize: Word(self.chrSize))
        self.prgBankOffsets[0] = DWord(self.prgCount - 1) * self.prgSize
    }

    private func loadRegister(_ data: Byte, for register: Byte) {
        guard !Bool(data & 0x80) else {
            self.shiftRegister = 0b10000
            self.controlRegister |= 0xC0
            return
        }

        let shouldPush = Bool(self.shiftRegister & 1)
        self.shiftRegister = (self.shiftRegister >> 1) | ((data & 1) << 4)

        if shouldPush {
            switch register {
            case 0:
                self.controlRegister = self.shiftRegister
                var mirroring: Mirroring!
                switch self.controlRegister & 0b11 {
                case 0: mirroring = .oneScreenLow
                case 1: mirroring = .oneScreenHigh
                case 2: mirroring = .vertical
                case 3: mirroring = .horizontal
                default: mirroring = .vertical
                }
                self.delegate.mapper(mapper: self, didChangeMirroring: mirroring)
            case 1: self.chrBankRegister0 = self.shiftRegister
            case 2: self.chrBankRegister1 = self.shiftRegister
            case 3: self.prgBankRegister = self.shiftRegister & 0x0F
            default: break
            }
            self.shiftRegister = 0b10000
            self.updateBanks(prgMode: self.controlRegister >> 2 & 0b11,
                             chrMode: self.controlRegister >> 4 & 1)
        }
    }

    private func updateBanks(prgMode: Byte, chrMode: Byte) {
        switch prgMode {
        case 0, 1:
            self.prgBankOffsets[0] = DWord(self.prgBankRegister & ~1)
            self.prgBankOffsets[1] = DWord(self.prgBankRegister | 1)
        case 2:
            self.prgBankOffsets[0] = 0
            self.prgBankOffsets[1] = DWord(self.prgBankRegister)
        case 3:
            self.prgBankOffsets[0] = DWord(self.prgBankRegister)
            self.prgBankOffsets[1] = DWord(self.prgCount - 1)
        default: break
        }

        switch chrMode {
        case 0:
            self.chrBankOffsets[0] = DWord(self.chrBankRegister0 & ~1)
            self.chrBankOffsets[1] = DWord(self.chrBankRegister0 | 1)
        case 1:
            self.chrBankOffsets[0] = DWord(self.chrBankRegister0)
            self.chrBankOffsets[1] = DWord(self.chrBankRegister1)
        default: break
        }

        self.prgBankOffsets[0] = self.prgBankOffsets[0] % DWord(self.prgCount) * self.prgSize
        self.prgBankOffsets[1] = self.prgBankOffsets[1] % DWord(self.prgCount) * self.prgSize
        self.chrBankOffsets[0] = self.chrBankOffsets[0] % DWord(self.chrCount) * self.chrSize
        self.chrBankOffsets[1] = self.chrBankOffsets[1] % DWord(self.chrCount) * self.chrSize
    }

    func busRead(at address: Word) -> Byte {
        if address < 0x2000 {
            let address: DWord = self.chrBankOffsets[address / 0x1000] + DWord(address % 0x1000)
            return self.delegate.mapper(mapper: self, didReadAt: DWord(address), of: .chr)
        }

        if address >= 0x6000 && address < 0x8000 {
            let address: DWord = DWord(address - 0x6000)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .sram)
        }

        if address >= 0x8000 {
            var address: DWord = DWord(address - 0x8000)
            address = DWord(self.prgBankOffsets[address / 0x4000]) + address % 0x4000
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .prg)
        }

        print("MMC1 mapper invalid read at 0x\(address.hex())")
        return 0
    }

    func busWrite(_ data: Byte, at address: Word) {
        if address < 0x2000 {
            let address: DWord = self.chrBankOffsets[address / 0x1000] + DWord(address % 0x1000)
            return self.delegate.mapper(mapper: self, didWriteAt: address, of: .chr, data: data)
        }

        if address >= 0x6000 && address < 0x8000 {
            return self.delegate.mapper(mapper: self, didWriteAt: DWord(address - 0x6000), of: .sram, data: data)
        }

        if (address >= 0x8000 && address <= 0xFFFF) {
            return self.loadRegister(data, for: Byte(address >> 13 & 0b11))
        }

        print("MMC1 mapper invalid write 0x\(address.hex()) = 0x\(data.hex())")
    }
}
