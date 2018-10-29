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

import Foundation

class Conductor: GuardStatus {
    private let nes: NintendoEntertainmentSystem
    private let imageGenerator = ImageGenerator()
    private let renderer: Renderer
    private let loop: LogicLoop
    private let inputManager: InputManager
    private let filepath: String = "/Users/frigon/Downloads/roms/tetris.nes"

    var status: String {
        return """
        |------ General ------|
         File: \(self.filepath)
        \(self.loop.status)
        \(self.nes.status)
        """
    }
    
    init(with renderer: Renderer, drivenBy loop: LogicLoop, interactingWith inputManager: InputManager) {
        self.renderer = renderer
        self.loop = loop
        self.inputManager = inputManager
        
        let game: Cartridge = iNesFile.load(path: self.filepath)
        // * blows a bit into the cardridge *
        self.nes = NintendoEntertainmentSystem(load: game)
        
        self.loop.start(closure: self.loopClosure)
    }
    
    // Debug function
    func step() { self.nes.step() }
    
    private func loopClosure(_ deltaTime: Double) {
        self.processInput()
        self.update(deltaTime)
        self.render()
    }
    
    private func processInput() {
        self.nes.setInput(to: self.inputManager.buttons, for: .primary)
    }
    
    private func update(_ deltaTime: Double) {
        //self.nes.run(for: deltaTime)
    }
    
    private func render() {
        let image: [Byte] = self.imageGenerator.generate()
        autoreleasepool {
            self.renderer.draw(image)
        }
    }
}
