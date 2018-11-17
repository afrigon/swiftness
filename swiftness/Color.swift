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

class Color {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8

    init(_ value: UInt32) {
        // no alpha (0x123456)
        if value.leadingZeroBitCount >= 8 {
            self.red = UInt8(value & 0xFF0000 >> 16)
            self.green = UInt8(value & 0xFF00 >> 8)
            self.blue = UInt8(value & 0xFF)
            self.alpha = 0xFF
        } else {
            self.red = UInt8(value & 0xFF000000 >> 24)
            self.green = UInt8(value & 0xFF0000 >> 16)
            self.blue = UInt8(value & 0xFF00 >> 8)
            self.alpha = UInt8(value & 0xFF)
        }
    }

    init(greyscale: UInt8 = 0xFF, alpha: UInt8 = 0xFF) {
        self.red = greyscale
        self.green = greyscale
        self.blue = greyscale
        self.alpha = alpha
    }

    init(_ red: UInt8 = 0xFF, _ green: UInt8 = 0xFF, _ blue: UInt8 = 0xFF, alpha: UInt8 = 0xFF) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}
