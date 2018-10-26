//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

enum Button: Byte {
    case a = 1
    case b = 2
    case up = 4
    case down = 8
    case left = 16
    case right = 32
    case select = 64
    case start = 128
}

class Controller: BusConnectedComponent, GuardStatus {
    private var strobe: Byte = 0
    private var index: Byte = 1
    let buttons: Byte = 0
    
    var status: String {
        var buttonString = ""
        for i in 0..<8 {
            buttonString += String(describing: Button(rawValue: 1 << i))
            buttonString += ": \(self.buttons & 1 << i)\n"
        }
        
        return """
        |------- Input -------|
        \(buttonString)
        """
    }
    
    func busRead(at address: Word) -> Byte {
        defer {
            self.index = self.strobe.isLeastSignificantBitOn() ? 1 : self.index << 1
        }
        
        return self.buttons & self.index
    }
    
    func busWrite(_ data: Byte, at address: Word) {
        if data.isLeastSignificantBitOn() {
            self.index = 1
        }
        self.strobe = data
    }
}
