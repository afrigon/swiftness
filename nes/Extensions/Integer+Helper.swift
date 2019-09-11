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

typealias Byte = UInt8
typealias Word = UInt16
typealias DWord = UInt32
typealias QWord = UInt64

extension Array {
    subscript(index: UInt8) -> Element {
        get { return self[Int(index)] }
        set(newValue) { self[Int(index)] = newValue }
    }

    subscript(index: UInt16) -> Element {
        get { return self[Int(index)] }
        set(newValue) { self[Int(index)] = newValue }
    }

    subscript(index: UInt32) -> Element {
        get { return self[Int(index)] }
        set(newValue) { self[Int(index)] = newValue }
    }

    subscript(index: UInt64) -> Element {
        get { return self[Int(index)] }
        set(newValue) { self[Int(index)] = newValue }
    }
}

extension UInt8 {
    init(_ value: Bool) { self = value ? 1 : 0 }

    static postfix func ++ (value: inout UInt8) { value &+= 1 }
    static postfix func -- (value: inout UInt8) { value &-= 1 }
    static func + (left: UInt8, right: UInt16) -> UInt16 { return left.asWord() + right }
    static func &+ (left: UInt8, right: UInt16) -> UInt16 { return left.asWord() &+ right }
    static func - (left: UInt8, right: UInt16) -> UInt16 { return left.asWord() - right }
    static func &- (left: UInt8, right: UInt16) -> UInt16 { return left.asWord() &- right }
    static func ^ (left: UInt8, right: UInt16) -> UInt16 { return left.asWord() ^ right }

    func hex() -> String { return String(format:"%02X", self) }
    func bin() -> String { return String(self, radix: 2).frontPad(with: "0", toLength: 8) }
    func asWord() -> UInt16 { return UInt16(self) }
    func isZero() -> Bool { return self == 0 }
    func isSignBitOn() -> Bool { return Bool(self & 0b10000000) }
    func isLeastSignificantBitOn() -> Bool { return Bool(self & 1) }
    func isMostSignificantBitOn() -> Bool { return self.isSignBitOn() }
}

extension UInt16 {
    static postfix func ++ (value: inout UInt16) { value &+= 1 }
    static postfix func -- (value: inout UInt16) { value &-= 1 }
    static func + (left: UInt16, right: UInt8) -> UInt16 { return left + right.asWord() }
    static func &+ (left: UInt16, right: UInt8) -> UInt16 { return left &+ right.asWord() }
    static func - (left: UInt16, right: UInt8) -> UInt16 { return left - right.asWord() }
    static func &- (left: UInt16, right: UInt8) -> UInt16 { return left &- right.asWord() }

    func hex() -> String { return String(format:"%04X", self) }
    func bin() -> String { return String(self, radix: 2).frontPad(with: "0", toLength: 16) }
    func leftByte() -> UInt8 { return UInt8(self >> 8) }
    func rightByte() -> UInt8 { return UInt8(self & 0xFF) }
    func overflowsByte() -> Bool { return Bool(self > 0xFF) }
    func isSignBitOn() -> Bool { return Bool(self & 0b1000000000000000) }
    func isLeastSignificantBitOn() -> Bool { return Bool(self & 1) }
    func isMostSignificantBitOn() -> Bool { return self.isSignBitOn() }

    func isAtSamePage(than address: Word) -> Bool {
        return self >> 8 != address >> 8
    }
}

extension UInt32 {
    static postfix func ++ (value: inout UInt32) { value &+= 1 }
    static postfix func -- (value: inout UInt32) { value &-= 1 }

    func hex() -> String { return String(format:"%08X", self) }
    func bin() -> String { return String(self, radix: 2).frontPad(with: "0", toLength: 32) }
}

extension UInt64 {
    static postfix func ++ (value: inout UInt64) { value &+= 1 }
    static postfix func -- (value: inout UInt64) { value &-= 1 }
}
