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

import Cocoa

class Overlay: CATextLayer {
    override init() {
        super.init()
        self.font = NSFont(name: "Menlo", size: 14)
        self.fontSize = 14
        self.foregroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class ViewController: NSViewController, LogicLoopDelegate {
    private let overlay = Overlay()
    private let renderer: MetalRenderer? = MetalRenderer()
    private var loop = CVDisplayLinkLoop()
    private var conductor: Conductor?
    var inputResponder = InputResponder()

    private let overlayRefreshDelay: Double = 0.5
    private var elapsedTime: Double = 0

    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        if self.renderer != nil {
            self.view.layer?.addSublayer(self.renderer!.layer)
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        self.renderer?.layer.frame = self.view.frame
        self.overlay.frame = CGRect(x: 10,
                                    y: 5,
                                    width: self.view.layer!.frame.width - 20,
                                    height: self.view.layer!.frame.height - 10)
    }

    override func viewDidLoad() {
        guard let renderer = self.renderer, let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }

        let options: StartupOptions = appDelegate.options
        self.conductor = Conductor(use: options,
                                   with: renderer,
                                   drivenBy: self.loop,
                                   interactingWith: self.inputResponder)

        guard self.conductor != nil else {
            // dismiss view and return to menu
            return
        }

        self.inputResponder.add(closure: self.toggleOverlay, forKey: 99)    // F3
        self.inputResponder.add(closure: self.stepFrame, forKey: 98)        // F7
        self.inputResponder.add(closure: self.step, forKey: 100)            // F8
        self.loop.delegate = self
        self.toggleOverlay()
    }

    func logicLoop(loop: LogicLoop, didExecuteCallback deltaTime: Double) {
        if self.overlay.superlayer != nil {
            self.elapsedTime += deltaTime
            if self.elapsedTime >= self.overlayRefreshDelay {
                self.elapsedTime = 0
                self.overlay.string = self.conductor?.status
            }
        }
    }

    private func toggleOverlay() {
        self.overlay.superlayer == nil
            ? self.view.layer?.addSublayer(self.overlay)
            : self.overlay.removeFromSuperlayer()
    }

    private func step() {
        self.conductor?.step()
    }

    private func stepFrame() {
        self.conductor?.stepFrame()
    }
}
