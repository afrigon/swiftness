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

class ConsoleWindow: CenteredWindow {
    private var conductor: Conductor! = nil
    private var console: Console
    private let loop = CVDisplayLinkLoop()
    private let renderer: MetalRenderer! = MetalRenderer()
    private let inputManager = InputResponder()
    private static let scale: Int = 3

    init?(_ console: Console) {
        self.console = console
        super.init(width: CGFloat(self.console.screenWidth * ConsoleWindow.scale),
                   height: CGFloat(self.console.screenHeight * ConsoleWindow.scale),
                   styleMask: [.closable, .miniaturizable, .titled])

        guard self.renderer != nil else { return nil }

        self.conductor = Conductor(use: self.console, drivenBy: self.loop, renderedBy: self.renderer, interactingWith: self.inputManager)

        self.inputManager.add(closure: self.conductor.reset, forKey: 15) // reset, key: R
        self.makeFirstResponder(self.inputManager)

        self.contentView?.layer?.addSublayer(self.renderer.layer)
        self.contentView?.layer?.setNeedsLayout()
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        if self.renderer != nil && self.contentView != nil {
            self.renderer?.layer.frame = self.contentView!.bounds
        }
    }

    func willTerminate() {
        SaveManager.save(checksum: self.console.checksum, data: self.console.saveRam)
    }
}
