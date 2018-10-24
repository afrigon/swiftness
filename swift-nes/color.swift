//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Alexandre Frigon. All rights reserved.
//

class Color {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8
    
    init(_ value: UInt32) {
        // no alpha (0x123456)
        if (value.leadingZeroBitCount >= 8) {
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
