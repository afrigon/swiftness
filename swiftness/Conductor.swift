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

/// An object conducting the emulation, linking the actual emulator, display and inputs.
/// - Remark: The conductor can also be used without a `Renderer` and an `InputManager` to run in headless mode.
class Conductor {
    private var console: Console
    private let loop: LogicLoop
    private let inputManager: InputManager!
    private let renderer: Renderer!
    private var updateClosure = [(Double) -> Void]()

    /// Whether or not the conductor is running in headless mode.
    /// - Remark: Headless mode is engaged when `Renderer` and `InputManager` are nil
    var headless: Bool {
        return self.renderer == nil && self.inputManager == nil
    }

    /// Creates a nes conductor instance with the specified objects.
    /// - parameter console: Console object to conduct.
    /// - parameter loop: Loop object driving the conductor by calling the closure with appropriate timing.
    /// - parameter renderer: Renderer object drawing the emulator's frame to screen.
    /// - parameter inputManager: InputManager object handling user input and sending it to the console.
    init(use console: Console,
         drivenBy loop: LogicLoop,
         renderedBy renderer: Renderer? = nil,
         interactingWith inputManager: InputManager? = nil) {
        self.console = console
        self.loop = loop
        self.renderer = renderer
        self.inputManager = inputManager

        self.updateClosure.append(self.update(_:))
        self.loop.start(closure: self.headless ? self.headlessLoopClosure : self.loopClosure)
    }

    /// Resets the console as you would with the phisical button.
    func reset() {
        self.console.reset()
    }

    /// Adds the specified closure to the list of update closures, executed in order of insertion.
    /// - parameter closure: closure to call on conductor tick.
    func onUpdate(closure: @escaping (Double) -> Void) {
        self.updateClosure.append(closure)
    }

    // func onError() looks like a good idea to implement later

    /// Loop executed by the LogicLoop object.
    /// - Attention: this method should not be called manually.
    /// - parameter deltaTime: Time passed since last loop.
    private func loopClosure(_ deltaTime: Double) {
        self.processInput()
        for f in self.updateClosure { f(deltaTime) }
        self.render()
    }

    /// Loop executed by the LogicLoop object in headless mode.
    /// - Attention: this method should not be called manually.
    /// - parameter deltaTime: Time passed since last loop.
    private func headlessLoopClosure(_ deltaTime: Double) {
        for f in self.updateClosure { f(deltaTime) }
    }

    /// Copies the input manager state to the console.
    /// - Attention: this method should only be called by the loop closure.
    private func processInput() {
        self.console.setInputs(to: self.inputManager.buttons, for: .primary)
    }

    /// Runs the actual emulation of the console.
    /// - Attention: this method should only be called by the loop closure.
    /// - parameter deltaTime: Time passed since last tick.
    private func update(_ deltaTime: Double) {
        // dirty hack to make the emulator slow down when the fps is too slow
        // doesn't work very well, TODO: stop coding with foot lol
        self.console.run(for: min(0.02, deltaTime))
    }

    /// Renders the console's frame buffer to screen.
    /// - Attention: this method should only be called by the loop closure.
    private func render() {
        guard self.console.needsRender else { return }
        autoreleasepool { self.renderer.draw(self.console.framebuffer) }
    }
}
