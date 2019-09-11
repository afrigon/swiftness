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

typealias AccumulatorRegister = Byte
typealias XIndexRegister = Byte
typealias YIndexRegister = Byte
typealias StackPointerRegister = Byte
typealias ProgramCounterRegister = Word

struct Registers {
    var a: AccumulatorRegister      = 0x00
    var x: XIndexRegister           = 0x00
    var y: YIndexRegister           = 0x00
    var p: ProcessorStatusRegister  = ProcessorStatusRegister(Flag.alwaysOne | Flag.breaks)
    var sp: StackPointerRegister    = 0xFD
    var pc: ProgramCounterRegister  = 0x0000
}

class ProcessorStatusRegister {
    private var _value: Byte
    var value: Byte { return self._value }

    init(_ value: Byte) {
        self._value = value
    }

    static func &= (left: inout ProcessorStatusRegister, right: Byte) {
        left._value = right
    }

    func set(flags: Byte, if condition: Bool? = nil) {
        if let condition = condition {
            return condition ? self.set(flags: flags) : self.unset(flags)
        }

        self._value |= flags
    }

    func set(_ flag: Flag, if condition: Bool? = nil) {
        self.set(flags: flag.rawValue, if: condition)
    }

    func unset(_ flags: Byte) {
        self._value &= ~flags
    }

    func unset(_ flag: Flag) {
        self.unset(flag.rawValue)
    }

    func isSet(_ flag: Flag) -> Bool {
        return Bool(self.value & flag.rawValue)
    }

    func isNotSet(_ flag: Flag) -> Bool {
        return !self.isSet(flag)
    }

    func valueOf(_ flag: Flag) -> UInt8 {
        return self.isSet(flag) ? 1 : 0
    }

    func updateFor(_ value: Word) {
        self.updateFor(value.rightByte())
    }

    func updateFor(_ value: Byte) {
        self.set(.zero, if: value.isZero())
        self.set(.negative, if: value.isSignBitOn())
    }
}

enum Flag: UInt8 {
    case carry      = 1     // 0b00000001   C
    case zero       = 2     // 0b00000010   Z
    case interrupt  = 4     // 0b00000100   I
    case decimal    = 8     // 0b00001000   D
    case breaks     = 16    // 0b00010000   B
    case alwaysOne  = 32    // 0b00100000
    case overflow   = 64    // 0b01000000   V
    case negative   = 128   // 0b10000000   N

    static func | (left: Flag, right: Flag) -> UInt8 {
        return left.rawValue | right.rawValue
    }

    static func & (left: Flag, right: Flag) -> UInt8 {
        return left.rawValue & right.rawValue
    }

    static prefix func ~ (value: Flag) -> UInt8 {
        return ~value.rawValue
    }
}
