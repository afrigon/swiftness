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

import XCTest
@testable import swiftness_osx

class NintendoEntertainmentSystemTestsRoms: XCTestCase {
    private var nes: NintendoEntertainmentSystem!

    override func setUp() {
        self.nes = nil
    }

    func testInstructions() {
//        let bundle = Bundle(for: type(of: self))
//        let path = bundle.path(forResource: "cpu-instructions-tests", ofType: "nes")!
//        guard let program = NesFile.load(path: path) else {
//            return
//        }
//        self.nes = NintendoEntertainmentSystem(load: program)
//
//        self.nes.disableGraphics = true
//        self.nes.stepFrame(60)
//        while self.nes.bus.readByte(at: 0x6000) == 0x80 {
//            self.nes.stepFrame()
//        }
//        let result = self.stringSRAM()
//
//        XCTAssert(self.nes.bus.readByte(at: 0x6000) == 0, result)
    }

    func stringSRAM() -> String {
        var i: Word = 0x6004
        var value: Byte = 0
        var string = ""
        repeat {
            value = self.nes.bus.readByte(at: i)
            string += String(Character(UnicodeScalar(value)))
            i++
        } while (value != 0)
        return string
    }
}
