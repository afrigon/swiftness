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
    private var options: StartupOptions
    private let renderer: MetalRenderer? = MetalRenderer()
    private var loop = CVDisplayLinkLoop()
    var conductor: Conductor!
    var inputResponder = InputResponder()

    private var elapsedTime: Double = 0

    init(width: CGFloat, height: CGFloat, options: StartupOptions) {
        self.options = options
        super.init(width: width, height: height, styleMask: [.closable, .miniaturizable, .titled])

        if self.renderer != nil {
            self.contentView?.layer?.addSublayer(self.renderer!.layer)
            self.contentView?.layer?.setNeedsLayout()
            self.conductor = Conductor(use: self.options,
                                       with: self.renderer!,
                                       drivenBy: self.loop,
                                       interactingWith: self.inputResponder)
        }

        if let filepath = self.options.filepath {
            self.title = "Swiftness - \((filepath as NSString).lastPathComponent)"
        } else {
            self.title = "Swiftness"
        }
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        if self.renderer != nil && self.contentView != nil {
            self.renderer?.layer.frame = self.contentView!.bounds
        }
    }
}
