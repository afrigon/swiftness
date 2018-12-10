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

import Cocoa

extension NSColor {
//    static let tintColor = NSColor(red: 196/255.0, green: 122/255.0, blue: 49/255.0, alpha: 1.0)
//    static let backgroundColor = NSColor(red: 28/255.0, green: 28/255.0, blue: 28/255.0, alpha: 1.0)
    static let primary = NSColor(hex: 0xC47A31)
    static let darkContent = NSColor(hex: 0x242428)
    static let darkContainer = NSColor(hex: 0x343131)

    convenience init(hex: UInt32) {
        let red = CGFloat(hex >> 16 & 0xFF)
        let green = CGFloat(hex >> 8 & 0xFF)
        let blue = CGFloat(hex & 0xFF)
        self.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 255.0)
    }

    var lighterColor: NSColor {
        return self.shiftBrightness(-0.2)
    }

    var darkerColor: NSColor {
        return self.shiftBrightness(0.2)
    }

    func shiftBrightness(_ value: CGFloat) -> NSColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return NSColor(hue: hue, saturation: saturation, brightness: max(min(brightness + value, 0.0), 1.0), alpha: alpha)
    }
}
