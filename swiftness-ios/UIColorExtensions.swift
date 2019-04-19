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

import UIKit

public struct HSBA {
    public var hue: CGFloat = 0
    public var saturation: CGFloat = 0
    public var brightness: CGFloat = 0
    public var alpha: CGFloat = 0
}

public struct RGBA {
    public var red: CGFloat = 0
    public var green: CGFloat = 0
    public var blue: CGFloat = 0
    public var alpha: CGFloat = 0

    public static func + (lhs: RGBA, rhs: RGBA) -> RGBA {
        return RGBA(red: lhs.red + rhs.red, green: lhs.green + rhs.green, blue: lhs.blue + rhs.blue, alpha: lhs.alpha + rhs.alpha)
    }

    public static func - (lhs: RGBA, rhs: RGBA) -> RGBA {
        return RGBA(red: lhs.red - rhs.red, green: lhs.green - rhs.green, blue: lhs.blue - rhs.blue, alpha: lhs.alpha - rhs.alpha)
    }

    public static func * (lhs: RGBA, k: CGFloat) -> RGBA {
        return RGBA(red: lhs.red * k, green: lhs.green * k, blue: lhs.blue * k, alpha: lhs.alpha * k)
    }
}

extension UIColor {
    public var hsba: HSBA {
        var hsba = HSBA()
        self.getHue(&(hsba.hue), saturation: &(hsba.saturation), brightness: &(hsba.brightness), alpha: &(hsba.alpha))
        return hsba
    }

    public var rgba: RGBA {
        var rgba = RGBA()
        self.getRed(&(rgba.red), green: &(rgba.green), blue: &(rgba.blue), alpha: &(rgba.alpha))
        return rgba
    }

    public convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1) {
        let alpha = min(max(0, alpha), 1)
        let c = [red, green, blue].map { CGFloat(min(max(0, $0), 255)) / 255.0 }

        self.init(red: c[0], green: c[1], blue: c[2], alpha: alpha)
    }

    public convenience init(hex: Int, alpha: CGFloat = 1) {
        let (r, g, b) = ((hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff)
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    public convenience init(components c: HSBA) {
        self.init(hue: c.hue, saturation: c.saturation, brightness: c.brightness, alpha: c.alpha)
    }

    public convenience init(components c: RGBA) {
        self.init(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
    }

    public func lighter(by delta: CGFloat = 0.15) -> UIColor {
        var c = self.hsba
        c.brightness = min(c.brightness + delta, 1)
        return UIColor(components: c)
    }

    public func darker(by delta: CGFloat = 0.15) -> UIColor {
        var c = self.hsba
        c.brightness = max(c.brightness - delta, 0)
        return UIColor(components: c)
    }

    public func alterOpacity(by delta: CGFloat) -> UIColor {
        var c = self.hsba
        c.alpha = min(max(0, c.alpha + delta), 1)
        return UIColor(components: c)
    }

    public static func at(percentage: CGFloat, between from: UIColor, and to: UIColor) -> UIColor {
        guard percentage > 0 else { return from }
        guard percentage < 1 else { return to }

        let c = (to.rgba - from.rgba) * percentage + from.rgba
        return UIColor(components: c)
    }
}
