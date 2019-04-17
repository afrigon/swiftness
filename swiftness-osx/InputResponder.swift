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

import Cocoa

class InputResponder: NSResponder, InputManager {
    override var acceptsFirstResponder: Bool { return true }
    let buttonMap: [UInt16: Controller.Button] = [
        6: .a,          // z
        7: .b,          // x
        126: .up,       // up arrow
        125: .down,     // down arrow
        123: .left,     // left arrow
        124: .right,    // right arrow
        46: .start,     // m
        45: .select     // n
    ]
    var closures = [UInt16: () -> Void]()
    var buttons: Byte = 0

    func add(closure: @escaping () -> Void, forKey key: UInt16) {
        self.closures[key] = closure
    }

    func remove(closureForKey key: UInt16) {
        self.closures.removeValue(forKey: key)
    }

    override func keyDown(with event: NSEvent) {
        //print(event.keyCode)

        if let button = self.buttonMap[event.keyCode] {
            self.buttons |= button.rawValue
            return
        }

        if let closure = self.closures[event.keyCode] {
            closure()
        }
    }

    override func keyUp(with event: NSEvent) {
        if let button = self.buttonMap[event.keyCode] {
            self.buttons &= ~button.rawValue
        }
    }
}
