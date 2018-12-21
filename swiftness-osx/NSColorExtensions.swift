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

extension NSColor.Name {
    static let background = NSColor.Name("background")
    static let text = NSColor.Name("text")
    static let icon = NSColor.Name("icon")
    static let primary = NSColor.Name("primary")
    static let systemAccent = NSColor.Name("system-accent")

    static let codeKeywords = NSColor.Name("code-keywords")
    static let codeRegisters = NSColor.Name("code-registers")
    static let codeNumbers = NSColor.Name("code-numbers")
    //static let codeRaw = NSColor.Name("primary")
    static let codeRaw = NSColor.Name("text")
    static let codeLowkey = NSColor.Name("text-disabled")
    static let codeRegular = NSColor.Name("text")
    static let codeBackgroundHighlight = NSColor.Name("code-background-highlight")
}

extension NSColor {
    var lighterColor: NSColor { return self.shiftBrightness(0.025) }
    var darkerColor: NSColor { return self.shiftBrightness(-0.025) }

    convenience init(hex: UInt32) {
        let red = CGFloat(hex >> 16 & 0xFF)
        let green = CGFloat(hex >> 8 & 0xFF)
        let blue = CGFloat(hex & 0xFF)
        self.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 255.0)
    }

    func shiftBrightness(_ value: CGFloat) -> NSColor {
        guard let c = self.usingColorSpace(.sRGB) else {
            return .white
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        c.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return NSColor(hue: hue, saturation: saturation, brightness: min(max(brightness + value, 0.0), 1.0), alpha: alpha)
    }
}
