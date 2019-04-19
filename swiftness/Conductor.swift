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

import Foundation

class Conductor {
    private var console: Console
    private let loop: LogicLoop
    private let inputManager: InputManager!
    private let renderer: Renderer!

    private var updateClosure = [(Double) -> Void]()

    init(use console: Console,
         with renderer: Renderer,
         drivenBy loop: LogicLoop,
         interactingWith inputManager: InputManager) {
        self.console = console
        self.renderer = renderer
        self.loop = loop
        self.inputManager = inputManager

        self.updateClosure.append(self.update(_:))
        self.loop.start(closure: self.loopClosure)
    }

    func reset() {
        self.console.reset()
    }

    func add(closure: @escaping (Double) -> Void) {
        self.updateClosure.append(closure)
    }

    private func loopClosure(_ deltaTime: Double) {
        self.processInput()
        for f in self.updateClosure { f(deltaTime) }
        self.render()
    }

    private func headlessLoopClosure(_ deltaTime: Double) {
        for f in self.updateClosure { f(deltaTime) }
    }

    private func processInput() {
        self.console.setInputs(to: self.inputManager.buttons, for: .primary)
    }

    private func update(_ deltaTime: Double) {
        // dirty hack to make the emulator slow down when the fps is too slow
        // doesn't work very well
        self.console.run(for: min(0.02, deltaTime))
    }

    private func render() {
//        var buffer = FrameBuffer(width: NintendoEntertainmentSystem.screenWidth, height: NintendoEntertainmentSystem.screenHeight)
//
//        // pattern table debug
//        let p = Palette()
//        for y in 0..<16 * 8 {
//            for x in 0..<16 * 8 {
//                let tileIndex = Word(x) / 8 + Word(y) / 8 * 16
//                let address: Word = tileIndex * 16 + Word(y) % 8
//
//                let low = self.nes.ppu.vramRead(at: address)
//                let high = self.nes.ppu.vramRead(at: address + 8)
//
//                let offset = x % 8
//                let h: Byte = high >> (Byte(7) - Byte(offset)) & Byte(1)
//                let l: Byte = low >> (Byte(7) - Byte(offset)) & Byte(1)
//                let i: Byte = h << 1 | l
//                buffer.set(x: x, y: y, color: p[self.nes.ppu.paletteIndices[i]])
//            }
//        }
//
//        for y in 0..<16 * 8 {
//            for x in 0..<16 * 8 {
//                let tileIndex = Word(x) / 8 + Word(y) / 8 * 16
//                let address: Word = tileIndex * 16 + Word(y) % 8 + 0x1000
//
//                let low = self.nes.ppu.vramRead(at: address)
//                let high = self.nes.ppu.vramRead(at: address + 8)
//
//                let offset = x % 8
//                let h: Byte = high >> (Byte(7) - Byte(offset)) & Byte(1)
//                let l: Byte = low >> (Byte(7) - Byte(offset)) & Byte(1)
//                let i: Byte = h << 1 | l
//                buffer.set(x: x + 16*8, y: y, color: p[self.nes.ppu.paletteIndices[i]])
//            }
//        }
//
//        let height = NintendoEntertainmentSystem.screenHeight - 16 * 8
//
//        let sizeX = NintendoEntertainmentSystem.screenWidth / 8
//        let sizeY = height / 4
//        for y in 0..<height {
//            for x in 0..<NintendoEntertainmentSystem.screenWidth {
//                let i = y / sizeY + (x / sizeX * 4)
//                let color_pointer = self.nes.ppu.paletteIndices[i]
//                buffer.set(x: x, y: y + (NintendoEntertainmentSystem.screenHeight - height), color: p[color_pointer])
//            }
//        }


        // nametable debug
//        let p = Palette()
//        for y in 0..<30 {
//            for x in 0..<32 {
//                let tileIndex = y * 32 + x
//                let tileId = self.nes.ppu.vramRead(at: 0x2000 + Word(tileIndex))
//
//                for i in 0..<8 {
//                    let address: Word = Word(tileId) * 16 + Word(i) + 0x1000
//                    let low = self.nes.ppu.vramRead(at: address)
//                    let high = self.nes.ppu.vramRead(at: address + 8)
//
//                    for j in 0..<8 {
//                        let h: Byte = high >> (Byte(7) - Byte(j)) & Byte(1)
//                        let l: Byte = low >> (Byte(7) - Byte(j)) & Byte(1)
//                        let index: Byte = h << 1 | l
//                        buffer.set(x: x * 8 + j, y: y * 8 + i, color: p[self.nes.ppu.paletteIndices[index+12]])
//                    }
//                }
//            }
//        }

//        autoreleasepool { self.renderer.draw(&buffer) }
        if self.console.needsRender {
            autoreleasepool { self.renderer.draw(self.console.framebuffer) }
        }
    }
}
