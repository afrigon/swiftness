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

fileprivate enum RegisterType { case control, prgBank, chrBank0, chrBank1 }

fileprivate class MMC1Registers {
    private var shiftRegister: Byte = 0b10000
    private var controlRegister: Byte = 0
    private var prgBankRegister: Byte = 0
    private var chrBankRegister0: Byte = 0
    private var chrBankRegister1: Byte = 0

    fileprivate func write(_ data: Byte, to register: RegisterType) {
        guard !Bool(data & 0b10000000) else {
            self.shiftRegister = 0b10000
            self.controlRegister |= Byte(0b1100)
            return
        }

        let shouldPush = Bool(self.shiftRegister & 1)
        self.shiftRegister = (self.shiftRegister >> 1) | ((data & 1) << 4)

        if shouldPush {
            switch register {
            case .control: self.controlRegister = self.shiftRegister
            case .prgBank: self.prgBankRegister = self.shiftRegister
            case .chrBank0: self.chrBankRegister0 = self.shiftRegister
            case .chrBank1: self.chrBankRegister1 = self.shiftRegister
            }
            self.shiftRegister = 0b10000
        }
    }
}

class MMC1: Mapper {
    weak var delegate: MapperDelegate!

    private let bankSize: DWord = 0x4000
    private var lowerPrgIndex: UInt8 = 0
    private var higherPrgIndex: UInt8 = 1

    private var registers = MMC1Registers()

    required init(_ delegate: MapperDelegate) {
        self.delegate = delegate
        self.higherPrgIndex = self.delegate.programBankCount(for: self) - 1
    }

    func busRead(at address: Word) -> Byte {
        // missing ppu reads
        switch address {
        case 0..<0x2000:
            let address: DWord = DWord(address)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .chr)
        case 0x6000..<0x8000:
            let address: DWord = DWord(address - 0x6000)
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .sram)
        case 0x8000..<0xC000:
            let address: DWord = DWord(address - 0x8000) + DWord(self.lowerPrgIndex) * self.bankSize
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .prg)
        case 0xC000...0xFFFF:
            let address: DWord = DWord(address - 0xC000) + DWord(self.higherPrgIndex) * self.bankSize
            return self.delegate.mapper(mapper: self, didReadAt: address, of: .prg)
        default: return 0x00
        }
    }

    func busWrite(_ data: Byte, at address: Word) {
        switch address {
        case 0..<0x2000: self.delegate.mapper(mapper: self, didWriteAt: address, of: .chr, data: data)
        case 0x6000..<0x8000: self.delegate.mapper(mapper: self, didWriteAt: address - 0x6000, of: .sram, data: data)
        case 0x8000..<0xA000: self.registers.write(data, to: .control)
        case 0xA000..<0xC000: self.registers.write(data, to: .chrBank0)
        case 0xC000..<0xE000: self.registers.write(data, to: .chrBank1)
        case 0xE000...0xFFFF: self.registers.write(data, to: .prgBank)
        default: return
        }
    }
}
