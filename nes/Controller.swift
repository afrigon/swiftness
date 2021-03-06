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

public class Controller: BusConnectedComponent {
    private let player: Player
    private var strobe: Byte = 0
    private var index: Byte = 0
    var buttons: Byte = 0

    public enum Button: UInt8 {
        case a = 1
        case b = 2
        case select = 4
        case start = 8
        case up = 16
        case down = 32
        case left = 64
        case right = 128
    }

    public enum Player: UInt8 {
        case primary = 1, secondary = 2
    }

    init(_ player: Player = .primary) {
        self.player = player
    }

    func busRead(at address: Word) -> Byte {
        defer {
            self.index = (self.index + 1) % 8
        }

        return self.buttons >> self.index & 1
    }

    func busWrite(_ data: Byte, at address: Word) {
        if data.isLeastSignificantBitOn() {
            self.index = 0
        }
        self.strobe = data
    }
}
