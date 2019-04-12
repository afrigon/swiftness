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

protocol EmulatorDelegate: AnyObject {
    func emulator(nes: NintendoEntertainmentSystem, shouldRenderFrame frameBuffer: FrameBuffer)
}

class Conductor: EmulatorDelegate {
    private weak var nextFrameBuffer: FrameBuffer?
    private var nes: NintendoEntertainmentSystem! = nil
    private let renderer: Renderer
    private let loop: LogicLoop
    private let inputManager: InputManager
    private var updateClosure = [(Double) -> Void]()
    private let options: StartupOptions

    init?(use options: StartupOptions,
         with renderer: Renderer,
         drivenBy loop: LogicLoop,
         interactingWith inputManager: InputManager) {
        self.options = options
        self.renderer = renderer
        self.loop = loop
        self.inputManager = inputManager

        guard self.options.mode != .test, let filepath = self.options.filepath else {
            return nil
        }

        guard let game: Cartridge = NesFile.load(path: filepath) else { return nil }
        // * blows a bit into the cardridge *
        self.nes = NintendoEntertainmentSystem(load: game, hostedBy: self)

        self.updateClosure.append(self.update(_:))
        self.loop.start(closure: self.loopClosure)
    }

    func attach() -> Debugger {
        self.options.mode = .debug
        let debugger = Debugger(nes: self.nes)
        self.updateClosure.append(debugger.loopClosure(_:))
        return debugger
    }

    private func loopClosure(_ deltaTime: Double) {
        self.processInput()
        for f in self.updateClosure {
            f(deltaTime)
        }
        self.render()
    }

    private func processInput() {
        self.nes.setInputs(to: self.inputManager.buttons, for: .primary)
    }

    private func update(_ deltaTime: Double) {
        if self.options.mode == .normal {
            self.nes.run(for: deltaTime)
        }
    }

    private func render() {
        guard self.nextFrameBuffer != nil else {
            return
        }

        autoreleasepool { self.renderer.draw(self.nextFrameBuffer!) }
        self.nextFrameBuffer = nil
    }

    func emulator(nes: NintendoEntertainmentSystem, shouldRenderFrame frameBuffer: FrameBuffer) {
        self.nextFrameBuffer = frameBuffer
    }
}
