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

import nes

class NesConsole: Console {
    var console: nes

    var screenWidth: Int {
        return self.console.screenWidth
    }

    var screenHeight: Int {
        return self.console.screenHeight
    }

    var mainColor: UInt32 {
        return self.console.mainColor
    }

    var needsRender: Bool {
        return self.console.needsRender
    }

    var framebuffer: UnsafeBufferPointer<UInt8> {
        return self.console.framebuffer
    }

    var saveRam: UnsafeBufferPointer<UInt8> {
        return self.console.saveRam
    }

    var checksum: String {
        return self.console.checksum
    }

    func run(for deltaTime: Double) {
        self.console.run(for: deltaTime)
    }

    func reset() {
        self.console.reset()
    }

    func setInputs(to value: UInt8, for player: UInt8) {
        self.console.setInputs(to: value, for: Controller.Player.primary)
    }

    init(rom: Cartridge) {
        self.console = nes(load: rom,
                       saveRam: SaveManager.load(checksum: rom.checksum,
                                                 size: rom.saveRamSize))
    }
}
