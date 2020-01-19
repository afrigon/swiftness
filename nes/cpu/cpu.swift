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

struct Opcode {
    let closure: (Operand) -> Void
    let name: String
    let cycles: UInt8
    let addressingMode: AddressingMode
}

struct Operand {
    var value: Word = 0x0000
    var address: Word = 0x0000
}

class CoreProcessingUnit {
    private weak var bus: Bus!

    private var regs: Registers = Registers()
    private var opcodes: [Opcode]! = nil

    private var pendingInterrupt: InterruptType?
    private var additionalCycles: UInt8 = 0
    private var stallCycles: UInt16 = 0
    private var totalCycles: UInt64 = 0

    let frequency: Double = 1789773

    init(using bus: Bus) {
        self.bus = bus
        
        self.opcodes = [
            Opcode(closure: brk, name: "brk", cycles: 7, addressingMode: .implied),                 // 0x00
            Opcode(closure: ora, name: "ora", cycles: 6, addressingMode: .indirect(.x)),            // 0x01
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x02
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x03
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x04
            Opcode(closure: ora, name: "ora", cycles: 3, addressingMode: .zeroPage(.none)),         // 0x05
            Opcode(closure: asl, name: "asl", cycles: 5, addressingMode: .zeroPage(.none)),         // 0x06
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x07
            Opcode(closure: php, name: "php", cycles: 3, addressingMode: .implied),                 // 0x08
            Opcode(closure: ora, name: "ora", cycles: 2, addressingMode: .immediate),               // 0x09
            Opcode(closure: asla, name: "asl", cycles: 2, addressingMode: .accumulator),            // 0x0A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x0B
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x0C
            Opcode(closure: ora, name: "ora", cycles: 4, addressingMode: .absolute(.none, true)),   // 0x0D
            Opcode(closure: asl, name: "asl", cycles: 6, addressingMode: .absolute(.none, true)),   // 0x0E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x0F
            Opcode(closure: bpl, name: "bpl", cycles: 2, addressingMode: .relative),                // 0x10
            Opcode(closure: ora, name: "ora", cycles: 5, addressingMode: .indirect(.y)),            // 0x11
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x12
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x13
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x14
            Opcode(closure: ora, name: "ora", cycles: 4, addressingMode: .zeroPage(.x)),            // 0x15
            Opcode(closure: asl, name: "asl", cycles: 6, addressingMode: .zeroPage(.x)),            // 0x16
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x17
            Opcode(closure: clc, name: "clc", cycles: 2, addressingMode: .implied),                 // 0x18
            Opcode(closure: ora, name: "ora", cycles: 4, addressingMode: .absolute(.y, true)),      // 0x19
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x1A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x1B
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x1C
            Opcode(closure: ora, name: "ora", cycles: 4, addressingMode: .absolute(.x, true)),      // 0x1D
            Opcode(closure: asl, name: "asl", cycles: 7, addressingMode: .absolute(.x, true)),      // 0x1E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x1F
            Opcode(closure: jsr, name: "jsr", cycles: 6, addressingMode: .absolute(.none, false)),  // 0x20
            Opcode(closure: and, name: "and", cycles: 6, addressingMode: .indirect(.x)),            // 0x21
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x22
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x23
            Opcode(closure: bit, name: "bit", cycles: 3, addressingMode: .zeroPage(.none)),         // 0x24
            Opcode(closure: and, name: "and", cycles: 3, addressingMode: .zeroPage(.none)),         // 0x25
            Opcode(closure: rol, name: "rol", cycles: 5, addressingMode: .zeroPage(.none)),         // 0x26
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x27
            Opcode(closure: plp, name: "plp", cycles: 4, addressingMode: .implied),                 // 0x28
            Opcode(closure: and, name: "and", cycles: 2, addressingMode: .immediate),               // 0x29
            Opcode(closure: rola, name: "rol", cycles: 2, addressingMode: .accumulator),            // 0x2A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x2B
            Opcode(closure: bit, name: "bit", cycles: 4, addressingMode: .absolute(.none, true)),   // 0x2C
            Opcode(closure: and, name: "and", cycles: 2, addressingMode: .absolute(.none, true)),   // 0x2D
            Opcode(closure: rol, name: "rol", cycles: 6, addressingMode: .absolute(.none, true)),   // 0x2E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x2F
            Opcode(closure: bmi, name: "bmi", cycles: 2, addressingMode: .relative),                // 0x30
            Opcode(closure: and, name: "and", cycles: 5, addressingMode: .indirect(.y)),            // 0x31
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x32
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x33
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x34
            Opcode(closure: and, name: "and", cycles: 4, addressingMode: .zeroPage(.x)),            // 0x35
            Opcode(closure: rol, name: "rol", cycles: 6, addressingMode: .zeroPage(.x)),            // 0x36
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x37
            Opcode(closure: sec, name: "sec", cycles: 2, addressingMode: .implied),                 // 0x38
            Opcode(closure: and, name: "and", cycles: 4, addressingMode: .absolute(.y, true)),      // 0x39
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x3A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x3B
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x3C
            Opcode(closure: and, name: "and", cycles: 4, addressingMode: .absolute(.x, true)),      // 0x3D
            Opcode(closure: rol, name: "rol", cycles: 7, addressingMode: .absolute(.x, true)),      // 0x3E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x3F
            Opcode(closure: rti, name: "rti", cycles: 6, addressingMode: .implied),                 // 0x40
            Opcode(closure: eor, name: "eor", cycles: 6, addressingMode: .indirect(.x)),            // 0x41
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x42
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x43
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x44
            Opcode(closure: eor, name: "eor", cycles: 3, addressingMode: .zeroPage(.none)),         // 0x45
            Opcode(closure: lsr, name: "lsr", cycles: 5, addressingMode: .zeroPage(.none)),         // 0x46
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x47
            Opcode(closure: pha, name: "pha", cycles: 3, addressingMode: .implied),                 // 0x48
            Opcode(closure: eor, name: "eor", cycles: 2, addressingMode: .immediate),               // 0x49
            Opcode(closure: lsra, name: "lsr", cycles: 2, addressingMode: .accumulator),            // 0x4A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x4B
            Opcode(closure: jmp, name: "jmp", cycles: 3, addressingMode: .absolute(.none, false)),  // 0x4C
            Opcode(closure: eor, name: "eor", cycles: 4, addressingMode: .absolute(.none, true)),   // 0x4D
            Opcode(closure: lsr, name: "lsr", cycles: 6, addressingMode: .absolute(.none, true)),   // 0x4E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x4F
            Opcode(closure: bvc, name: "bvc", cycles: 2, addressingMode: .relative),                // 0x50
            Opcode(closure: eor, name: "eor", cycles: 5, addressingMode: .indirect(.y)),            // 0x51
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x52
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x53
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x54
            Opcode(closure: eor, name: "eor", cycles: 4, addressingMode: .zeroPage(.x)),            // 0x55
            Opcode(closure: lsr, name: "lsr", cycles: 6, addressingMode: .zeroPage(.x)),            // 0x56
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x57
            Opcode(closure: cli, name: "cli", cycles: 2, addressingMode: .implied),                 // 0x58
            Opcode(closure: eor, name: "eor", cycles: 4, addressingMode: .absolute(.y, true)),      // 0x59
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x5A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x5B
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x5C
            Opcode(closure: eor, name: "eor", cycles: 4, addressingMode: .absolute(.x, true)),      // 0x5D
            Opcode(closure: lsr, name: "lsr", cycles: 7, addressingMode: .absolute(.x, true)),      // 0x5E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x5F
            Opcode(closure: rts, name: "rts", cycles: 6, addressingMode: .implied),                 // 0x60
            Opcode(closure: adc, name: "adc", cycles: 6, addressingMode: .indirect(.x)),            // 0x61
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x62
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x63
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x64
            Opcode(closure: adc, name: "adc", cycles: 3, addressingMode: .zeroPage(.none)),         // 0x65
            Opcode(closure: ror, name: "ror", cycles: 5, addressingMode: .zeroPage(.none)),         // 0x66
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x67
            Opcode(closure: pla, name: "pla", cycles: 4, addressingMode: .implied),                 // 0x68
            Opcode(closure: adc, name: "adc", cycles: 2, addressingMode: .immediate),               // 0x69
            Opcode(closure: rora, name: "ror", cycles: 2, addressingMode: .accumulator),            // 0x6A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x6B
            Opcode(closure: jmp, name: "jmp", cycles: 5, addressingMode: .indirect(.none)),         // 0x6C
            Opcode(closure: adc, name: "adc", cycles: 4, addressingMode: .absolute(.none, true)),   // 0x6D
            Opcode(closure: ror, name: "ror", cycles: 6, addressingMode: .absolute(.none, true)),   // 0x6E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x6F
            Opcode(closure: bvs, name: "bvs", cycles: 2, addressingMode: .relative),                // 0x70
            Opcode(closure: adc, name: "adc", cycles: 5, addressingMode: .indirect(.y)),            // 0x71
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x72
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x73
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x74
            Opcode(closure: adc, name: "adc", cycles: 4, addressingMode: .zeroPage(.x)),            // 0x75
            Opcode(closure: ror, name: "ror", cycles: 6, addressingMode: .zeroPage(.x)),            // 0x76
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x77
            Opcode(closure: sei, name: "sei", cycles: 2, addressingMode: .implied),                 // 0x78
            Opcode(closure: adc, name: "adc", cycles: 4, addressingMode: .absolute(.y, true)),      // 0x79
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x7A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x7B
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x7C
            Opcode(closure: adc, name: "adc", cycles: 4, addressingMode: .absolute(.x, true)),      // 0x7D
            Opcode(closure: ror, name: "ror", cycles: 7, addressingMode: .absolute(.x, true)),      // 0x7E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x7F
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x80
            Opcode(closure: sta, name: "sta", cycles: 6, addressingMode: .indirect(.x)),            // 0x81
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x82
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x83
            Opcode(closure: sty, name: "sty", cycles: 3, addressingMode: .zeroPage(.none)),         // 0x84
            Opcode(closure: sta, name: "sta", cycles: 3, addressingMode: .zeroPage(.none)),         // 0x85
            Opcode(closure: stx, name: "stx", cycles: 3, addressingMode: .zeroPage(.none)),         // 0x86
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x87
            Opcode(closure: dey, name: "dey", cycles: 2, addressingMode: .implied),                 // 0x88
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x89
            Opcode(closure: txa, name: "txa", cycles: 2, addressingMode: .implied),                 // 0x8A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x8B
            Opcode(closure: sty, name: "sty", cycles: 4, addressingMode: .absolute(.none, false)),  // 0x8C
            Opcode(closure: sta, name: "sta", cycles: 4, addressingMode: .absolute(.none, false)),  // 0x8D
            Opcode(closure: stx, name: "stx", cycles: 4, addressingMode: .absolute(.none, false)),  // 0x8E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x8F
            Opcode(closure: bcc, name: "bcc", cycles: 2, addressingMode: .relative),                // 0x90
            Opcode(closure: sta, name: "sta", cycles: 6, addressingMode: .indirect(.y)),            // 0x91
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x92
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x93
            Opcode(closure: sty, name: "sty", cycles: 4, addressingMode: .zeroPage(.x)),            // 0x94
            Opcode(closure: sta, name: "sta", cycles: 4, addressingMode: .zeroPage(.x)),            // 0x95
            Opcode(closure: stx, name: "stx", cycles: 4, addressingMode: .zeroPage(.y)),            // 0x96
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x97
            Opcode(closure: tya, name: "tya", cycles: 2, addressingMode: .implied),                 // 0x98
            Opcode(closure: sta, name: "sta", cycles: 5, addressingMode: .absolute(.y, false)),     // 0x99
            Opcode(closure: txs, name: "txs", cycles: 2, addressingMode: .implied),                 // 0x9A
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x9B
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x9C
            Opcode(closure: sta, name: "sta", cycles: 5, addressingMode: .absolute(.x, false)),     // 0x9D
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x9E
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0x9F
            Opcode(closure: ldy, name: "ldy", cycles: 2, addressingMode: .immediate),               // 0xA0
            Opcode(closure: lda, name: "lda", cycles: 6, addressingMode: .indirect(.x)),            // 0xA1
            Opcode(closure: ldx, name: "ldx", cycles: 2, addressingMode: .immediate),               // 0xA2
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xA3
            Opcode(closure: ldy, name: "ldy", cycles: 3, addressingMode: .zeroPage(.none)),         // 0xA4
            Opcode(closure: lda, name: "lda", cycles: 3, addressingMode: .zeroPage(.none)),         // 0xA5
            Opcode(closure: ldx, name: "ldx", cycles: 3, addressingMode: .zeroPage(.none)),         // 0xA6
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xA7
            Opcode(closure: tay, name: "tay", cycles: 2, addressingMode: .implied),                 // 0xA8
            Opcode(closure: lda, name: "lda", cycles: 2, addressingMode: .immediate),               // 0xA9
            Opcode(closure: tax, name: "tax", cycles: 2, addressingMode: .implied),                 // 0xAA
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xAB
            Opcode(closure: ldy, name: "ldy", cycles: 4, addressingMode: .absolute(.none, true)),   // 0xAC
            Opcode(closure: lda, name: "lda", cycles: 4, addressingMode: .absolute(.none, true)),   // 0xAD
            Opcode(closure: ldx, name: "ldx", cycles: 4, addressingMode: .absolute(.none, true)),   // 0xAE
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xAF
            Opcode(closure: bcs, name: "bcs", cycles: 2, addressingMode: .relative),                // 0xB0
            Opcode(closure: lda, name: "lda", cycles: 5, addressingMode: .indirect(.y)),            // 0xB1
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xB2
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xB3
            Opcode(closure: ldy, name: "ldy", cycles: 4, addressingMode: .zeroPage(.x)),            // 0xB4
            Opcode(closure: lda, name: "lda", cycles: 4, addressingMode: .zeroPage(.x)),            // 0xB5
            Opcode(closure: ldx, name: "ldx", cycles: 4, addressingMode: .zeroPage(.y)),            // 0xB6
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xB7
            Opcode(closure: clv, name: "clv", cycles: 2, addressingMode: .implied),                 // 0xB8
            Opcode(closure: lda, name: "lda", cycles: 4, addressingMode: .absolute(.y, true)),      // 0xB9
            Opcode(closure: tsx, name: "tsx", cycles: 2, addressingMode: .implied),                 // 0xBA
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xBB
            Opcode(closure: ldy, name: "ldy", cycles: 4, addressingMode: .absolute(.x, true)),      // 0xBC
            Opcode(closure: lda, name: "lda", cycles: 4, addressingMode: .absolute(.x, true)),      // 0xBD
            Opcode(closure: ldx, name: "ldx", cycles: 4, addressingMode: .absolute(.y, true)),      // 0xBE
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xBF
            Opcode(closure: cpy, name: "cpy", cycles: 2, addressingMode: .immediate),               // 0xC0
            Opcode(closure: cmp, name: "cmp", cycles: 6, addressingMode: .indirect(.x)),            // 0xC1
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xC2
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xC3
            Opcode(closure: cpy, name: "cpy", cycles: 3, addressingMode: .zeroPage(.none)),         // 0xC4
            Opcode(closure: cmp, name: "cmp", cycles: 3, addressingMode: .zeroPage(.none)),         // 0xC5
            Opcode(closure: dec, name: "dec", cycles: 5, addressingMode: .zeroPage(.none)),         // 0xC6
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xC7
            Opcode(closure: iny, name: "iny", cycles: 2, addressingMode: .implied),                 // 0xC8
            Opcode(closure: cmp, name: "cmp", cycles: 2, addressingMode: .immediate),               // 0xC9
            Opcode(closure: dex, name: "dex", cycles: 2, addressingMode: .implied),                 // 0xCA
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xCB
            Opcode(closure: cpy, name: "cpy", cycles: 4, addressingMode: .absolute(.none, true)),   // 0xCC
            Opcode(closure: cmp, name: "cmp", cycles: 4, addressingMode: .absolute(.none, true)),   // 0xCD
            Opcode(closure: dec, name: "dec", cycles: 6, addressingMode: .absolute(.none, true)),   // 0xCE
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xCF
            Opcode(closure: bne, name: "bne", cycles: 2, addressingMode: .relative),                // 0xD0
            Opcode(closure: cmp, name: "cmp", cycles: 5, addressingMode: .indirect(.y)),            // 0xD1
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xD2
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xD3
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xD4
            Opcode(closure: cmp, name: "cmp", cycles: 4, addressingMode: .zeroPage(.x)),            // 0xD5
            Opcode(closure: dec, name: "dec", cycles: 6, addressingMode: .zeroPage(.x)),            // 0xD6
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xD7
            Opcode(closure: cld, name: "cld", cycles: 2, addressingMode: .implied),                 // 0xD8
            Opcode(closure: cmp, name: "cmp", cycles: 4, addressingMode: .absolute(.y, true)),      // 0xD9
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xDA
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xDB
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xDC
            Opcode(closure: cmp, name: "cmp", cycles: 4, addressingMode: .absolute(.x, true)),      // 0xDD
            Opcode(closure: dec, name: "dec", cycles: 7, addressingMode: .absolute(.x, true)),      // 0xDE
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xDF
            Opcode(closure: cpx, name: "cpx", cycles: 2, addressingMode: .immediate),               // 0xE0
            Opcode(closure: sbc, name: "sbc", cycles: 6, addressingMode: .indirect(.x)),            // 0xE1
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xE2
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xE3
            Opcode(closure: cpx, name: "cpx", cycles: 3, addressingMode: .zeroPage(.none)),         // 0xE4
            Opcode(closure: sbc, name: "sbc", cycles: 3, addressingMode: .zeroPage(.none)),         // 0xE5
            Opcode(closure: inc, name: "inc", cycles: 5, addressingMode: .zeroPage(.none)),         // 0xE6
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xE7
            Opcode(closure: inx, name: "inx", cycles: 2, addressingMode: .implied),                 // 0xE8
            Opcode(closure: sbc, name: "sbc", cycles: 2, addressingMode: .immediate),               // 0xE9
            Opcode(closure: nop, name: "nop", cycles: 2, addressingMode: .implied),                 // 0xEA
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xEB
            Opcode(closure: cpx, name: "cpx", cycles: 4, addressingMode: .absolute(.none, true)),   // 0xEC
            Opcode(closure: sbc, name: "sbc", cycles: 4, addressingMode: .absolute(.none, true)),   // 0xED
            Opcode(closure: inc, name: "inc", cycles: 6, addressingMode: .absolute(.none, true)),   // 0xEE
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xEF
            Opcode(closure: beq, name: "beq", cycles: 2, addressingMode: .relative),                // 0xF0
            Opcode(closure: sbc, name: "sbc", cycles: 5, addressingMode: .indirect(.y)),            // 0xF1
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xF2
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xF3
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xF4
            Opcode(closure: sbc, name: "sbc", cycles: 4, addressingMode: .zeroPage(.x)),            // 0xF5
            Opcode(closure: inc, name: "inc", cycles: 6, addressingMode: .zeroPage(.x)),            // 0xF6
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xF7
            Opcode(closure: sed, name: "sed", cycles: 2, addressingMode: .implied),                 // 0xF8
            Opcode(closure: sbc, name: "sbc", cycles: 4, addressingMode: .absolute(.y, true)),      // 0xF9
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xFA
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xFB
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xFC
            Opcode(closure: sbc, name: "sbc", cycles: 4, addressingMode: .absolute(.x, true)),      // 0xFD
            Opcode(closure: inc, name: "inc", cycles: 7, addressingMode: .absolute(.x, true)),      // 0xFE
            Opcode(closure: bad, name: "(bad)", cycles: 0, addressingMode: .implied),               // 0xFF
        ]
    }

    func stall(for cycles: UInt16) {
        self.stallCycles += cycles + UInt16(self.totalCycles % 2 != 0 ? 1 : 0)
    }

    func requestInterrupt(type: InterruptType) {
        guard type != .irq || self.regs.p.isNotSet(.interrupt) else { return }
        self.pendingInterrupt = type
    }

    @discardableResult
    func step() -> UInt8 {
        if self.stallCycles > 0 {
            self.stallCycles--
            self.totalCycles++
            return 1
        }

        if let interrupt = self.pendingInterrupt {
            let cycles = self.interrupt(type: interrupt)
            self.totalCycles += UInt64(cycles)
            return cycles
        }

        let opcodeHex: Byte = self.bus.readByte(at: regs.pc)
        regs.pc++
        
        let opcode = self.opcodes[opcodeHex]
        let operand: Operand = self.buildOperand(using: opcode.addressingMode)
        opcode.closure(operand)

        let cycles = opcode.cycles + self.additionalCycles
        self.additionalCycles = 0
        self.totalCycles += UInt64(cycles)

        return cycles
    }

    @discardableResult
    private func interrupt(type: InterruptType) -> UInt8 {
        self.pendingInterrupt = nil

        if type == .reset {
            self.regs.sp = 0xFD
        } else {
            self.pushWord(data: self.regs.pc)
            self.pushByte(data: self.regs.p.value | Flag.alwaysOne.rawValue)
        }

        self.regs.p.set(.interrupt)
        self.regs.pc = self.bus.readWord(at: type.address)

        return 7
    }

    private func pushByte(data: Byte) {
        self.bus.writeByte(data, at: self.regs.sp.asWord() + 0x100)
        self.regs.sp--
    }

    private func popByte() -> Byte {
        self.regs.sp++
        return self.bus.readByte(at: self.regs.sp.asWord() + 0x100)
    }

    private func pushWord(data: Word) {
        self.pushByte(data: data.leftByte())
        self.pushByte(data: data.rightByte())
    }

    private func popWord() -> Word {
        return self.popByte().asWord() + self.popByte().asWord() << 8
    }

    private func buildOperand(using addressingMode: AddressingMode) -> Operand {
        switch addressingMode {
        case .zeroPage(let alteration):
            let alterationValue: Byte = alteration != .none ? (alteration == .x ? regs.x : regs.y) : 0
            var operand = Operand()
            operand.address = (self.bus.readByte(at: regs.pc).asWord() + alterationValue) & 0xFF
            operand.value = self.bus.readByte(at: operand.address).asWord()
            regs.pc++
            return operand
        case .absolute(let alteration, let shouldFetchValue):
            let alterationValue: Byte = alteration != .none ? (alteration == .x ? regs.x : regs.y) : 0
            var operand = Operand()
            operand.address = self.bus.readWord(at: regs.pc) + alterationValue
            if shouldFetchValue { operand.value = self.bus.readByte(at: operand.address).asWord() }
            regs.pc += 2
            self.additionalCycles = alteration == .none
                ? 0
                : UInt8(operand.address.isAtSamePage(than: operand.address - (alteration == .x
                    ? regs.x
                    : regs.y)))
            return operand
        case .relative:
            var operand = Operand()

            // transform the relative address into an absolute address
            let value = self.bus.readByte(at: regs.pc)
            regs.pc++
            operand.address = regs.pc
            if value.isSignBitOn() {
                operand.address -= Word(128 - value & 0b01111111)
            } else {
                operand.address += value.asWord() & 0b01111111
            }

            self.additionalCycles = UInt8(regs.pc.isAtSamePage(than: operand.address))
            return operand
        case .indirect(let alteration):
            let addressPointer: Word = ((alteration == .none
                ? self.bus.readWord(at: regs.pc)
                : self.bus.readByte(at: regs.pc).asWord())
                + (alteration == .x ? regs.x.asWord() : 0))
                & (alteration == .none ? 0xFFFF : 0xFF)

            var operand = Operand()
            operand.address = self.bus.readWordGlitched(at: addressPointer) &+ (alteration == .y ? regs.y : 0)
            operand.value = self.bus.readByte(at: operand.address).asWord()

            regs.pc += alteration == .none ? 2 : 1
            self.additionalCycles = alteration == .y ? UInt8(operand.address.isAtSamePage(than: operand.address &- regs.y)) : 0
            return operand
        case .immediate:
            var operand = Operand()
            operand.value = self.bus.readByte(at: regs.pc).asWord()
            regs.pc++
            return operand
        case .implied, .accumulator: fallthrough
        default: return Operand()
        }
    }

    // OPCODES IMPLEMENTATION
    private func bad(_ operand: Operand) { fatalError("unknown opcode") }
    private func nop(_ operand: Operand) {}

    // Math
    private func inx(_ operand: Operand) { regs.x++; regs.p.updateFor(regs.x) }
    private func iny(_ operand: Operand) { regs.y++; regs.p.updateFor(regs.y) }
    private func dex(_ operand: Operand) { regs.x--; regs.p.updateFor(regs.x) }
    private func dey(_ operand: Operand) { regs.y--; regs.p.updateFor(regs.y) }

    private func adc(_ operand: Operand) {
        let result: Word = regs.a &+ operand.value &+ regs.p.valueOf(.carry)
        regs.p.set(.carry, if: result.overflowsByte())
        regs.p.set(.overflow, if: Bool(~(regs.a ^ operand.value) & Word(regs.a ^ result) & Word(Flag.negative.rawValue)))
        regs.a = result.rightByte()
        regs.p.updateFor(regs.a)
    }

    private func sbc(_ operand: Operand) {
        let result: Word = regs.a &- operand.value &- (1 - regs.p.valueOf(.carry))
        regs.p.set(.carry, if: !result.overflowsByte())
        regs.p.set(.overflow, if: Bool((regs.a ^ operand.value) & Word(regs.a ^ result) & Word(Flag.negative.rawValue)))
        regs.a = result.rightByte()
        regs.p.updateFor(regs.a)
    }

    private func inc(_ operand: Operand) {
        let result: Byte = operand.value.rightByte() &+ 1
        self.bus.writeByte(result, at: operand.address)
        regs.p.updateFor(result)
    }

    private func dec(_ operand: Operand) {
        let result: Byte = operand.value.rightByte() &- 1
        self.bus.writeByte(result, at: operand.address)
        regs.p.updateFor(result)
    }

    // Bitwise
    private func and(_ operand: Operand) { regs.a &= Byte(operand.value); regs.p.updateFor(regs.a) }
    private func eor(_ operand: Operand) { regs.a ^= Byte(operand.value); regs.p.updateFor(regs.a) }
    private func ora(_ operand: Operand) { regs.a |= Byte(operand.value); regs.p.updateFor(regs.a) }

    private func bit(_ operand: Operand) {
        regs.p.set(.zero, if: !Bool(regs.a & Byte(operand.value)))
        regs.p.set(.overflow, if: Bool(Flag.overflow.rawValue & Byte(operand.value)))
        regs.p.set(.negative, if: Bool(Flag.negative.rawValue & Byte(operand.value)))
    }

    private func asl(_ operand: Operand) {
        regs.p.set(.carry, if: operand.value.rightByte().isMostSignificantBitOn())
        let result: Byte = operand.value.rightByte() << 1
        regs.p.updateFor(result)
        self.bus.writeByte(result, at: operand.address)
    }

    private func lsr(_ operand: Operand) {
        regs.p.set(.carry, if: operand.value.rightByte().isLeastSignificantBitOn())
        let result: Byte = operand.value.rightByte() >> 1
        regs.p.updateFor(result)
        self.bus.writeByte(result, at: operand.address)
    }

    private func rol(_ operand: Operand) {
        let result: Word = operand.value << 1 | Word(regs.p.valueOf(.carry))
        regs.p.set(.carry, if: Bool(result & 0x100))
        self.bus.writeByte(result.rightByte(), at: operand.address)
        regs.p.updateFor(result)
    }

    private func ror(_ operand: Operand) {
        let carry: Byte = regs.p.valueOf(.carry)
        regs.p.set(.carry, if: operand.value.isLeastSignificantBitOn())
        let result: Byte = operand.value.rightByte() >> 1 | carry << 7
        regs.p.updateFor(result)
        self.bus.writeByte(result, at: operand.address)
    }

    private func asla(_ operand: Operand) {
        regs.p.set(.carry, if: regs.a.isMostSignificantBitOn())
        regs.a <<= 1
        regs.p.updateFor(regs.a)
    }

    private func lsra(_ operand: Operand) {
        regs.p.set(.carry, if: regs.a.isLeastSignificantBitOn())
        regs.a >>= 1
        regs.p.updateFor(regs.a)
    }

    private func rola(_ operand: Operand) {
        let carry: Byte = regs.p.valueOf(.carry)
        regs.p.set(.carry, if: regs.a.isSignBitOn())
        regs.a = regs.a << 1 | carry
        regs.p.updateFor(regs.a)
    }

    private func rora(_ operand: Operand) {
        let carry: Byte = regs.p.valueOf(.carry)
        regs.p.set(.carry, if: regs.a.isLeastSignificantBitOn())
        regs.a = regs.a >> 1 | carry << 7
        regs.p.updateFor(regs.a)
    }

    // flags
    private func clc(_ operand: Operand) { regs.p.unset(.carry) }
    private func cld(_ operand: Operand) { regs.p.unset(.decimal) }
    private func cli(_ operand: Operand) { regs.p.unset(.interrupt) }
    private func clv(_ operand: Operand) { regs.p.unset(.overflow) }
    private func sec(_ operand: Operand) { regs.p.set(.carry) }
    private func sed(_ operand: Operand) { regs.p.set(.decimal) }
    private func sei(_ operand: Operand) { regs.p.set(.interrupt) }

    // comparison
    private func compare(_ register: Byte, _ value: Word) {
        regs.p.updateFor(register &- value.rightByte())
        regs.p.set(.carry, if: register >= value)
    }
    private func cmp(_ operand: Operand) { compare(regs.a, operand.value) }
    private func cpx(_ operand: Operand) { compare(regs.x, operand.value) }
    private func cpy(_ operand: Operand) { compare(regs.y, operand.value) }

    // branches
    private func branch(to operand: Operand, if condition: Bool) {
        guard condition else {
            self.additionalCycles = 0
            return
        }

        regs.pc = operand.address
        self.additionalCycles++
    }
    private func beq(_ operand: Operand) { branch(to: operand, if: regs.p.isSet(.zero)) }
    private func bne(_ operand: Operand) { branch(to: operand, if: !regs.p.isSet(.zero)) }
    private func bmi(_ operand: Operand) { branch(to: operand, if: regs.p.isSet(.negative)) }
    private func bpl(_ operand: Operand) { branch(to: operand, if: !regs.p.isSet(.negative)) }
    private func bcs(_ operand: Operand) { branch(to: operand, if: regs.p.isSet(.carry)) }
    private func bcc(_ operand: Operand) { branch(to: operand, if: !regs.p.isSet(.carry)) }
    private func bvs(_ operand: Operand) { branch(to: operand, if: regs.p.isSet(.overflow)) }
    private func bvc(_ operand: Operand) { branch(to: operand, if: !regs.p.isSet(.overflow)) }

    // jump
    private func jmp(_ operand: Operand) { regs.pc = operand.address }

    // subroutines
    private func jsr(_ operand: Operand) { self.pushWord(data: regs.pc &- 1); regs.pc = operand.address }
    private func rts(_ operand: Operand) { regs.pc = self.popWord() &+ 1 }

    // interruptions
    private func rti(_ operand: Operand) {
        regs.p &= self.popByte() | Flag.alwaysOne.rawValue
        regs.pc = self.popWord()
    }

    private func brk(_ operand: Operand) {
        self.regs.p.set(.breaks)
        self.interrupt(type: .irq)
    }

    // stack
    private func pha(_ operand: Operand) { self.pushByte(data: regs.a) }
    private func php(_ operand: Operand) { self.pushByte(data: regs.p.value | (.alwaysOne | .breaks)) }
    private func pla(_ operand: Operand) { regs.a = self.popByte(); regs.p.updateFor(regs.a) }
    private func plp(_ operand: Operand) { regs.p &= self.popByte() & ~Flag.breaks.rawValue | Flag.alwaysOne.rawValue }

    // loading
    private func load(_ a: inout Byte, _ operand: Word) { a = operand.rightByte(); regs.p.updateFor(a) }
    private func lda(_ operand: Operand) { self.load(&regs.a, operand.value) }
    private func ldx(_ operand: Operand) { self.load(&regs.x, operand.value) }
    private func ldy(_ operand: Operand) { self.load(&regs.y, operand.value) }

    // storing
    private func sta(_ operand: Operand) { self.bus.writeByte(regs.a, at: operand.address) }
    private func stx(_ operand: Operand) { self.bus.writeByte(regs.x, at: operand.address) }
    private func sty(_ operand: Operand) { self.bus.writeByte(regs.y, at: operand.address) }

    // transfering
    private func transfer(_ a: inout Byte, _ b: Byte) { a = b; regs.p.updateFor(a) }
    private func tax(_ operand: Operand) { self.transfer(&regs.x, regs.a) }
    private func txa(_ operand: Operand) { self.transfer(&regs.a, regs.x) }
    private func tay(_ operand: Operand) { self.transfer(&regs.y, regs.a) }
    private func tya(_ operand: Operand) { self.transfer(&regs.a, regs.y) }
    private func tsx(_ operand: Operand) { self.transfer(&regs.x, regs.sp) }
    private func txs(_ operand: Operand) { regs.sp = regs.x }
}
