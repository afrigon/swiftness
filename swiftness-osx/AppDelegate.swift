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

class CenteredWindow: NSWindow {
    init(width: CGFloat, height: CGFloat, styleMask style: NSWindow.StyleMask) {
        guard let screen = NSScreen.main else {
            fatalError("User has no screen, wtf?!")
        }

        let frame = CGRect(x: screen.frame.midX - width / 2,
                           y: screen.frame.midY - height / 2,
                           width: width,
                           height: height)

        super.init(contentRect: frame,
                   styleMask: style,
                   backing: .buffered,
                   defer: false)

        self.contentView?.wantsLayer = true
    }

    func getWindowController() -> NSWindowController {
        return NSWindowController(window: self)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let scale = 3
    private var windowController: NSWindowController!
    private var window: ConsoleWindow!

    let options: StartupOptions
    var conductor: Conductor { return self.window.conductor }

    init(_ options: StartupOptions) {
        self.options = options
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let width = CGFloat(256 * self.scale)
        let height = CGFloat(240 * self.scale)

        self.window = ConsoleWindow(width: width, height: height, options: self.options)
        self.window.makeFirstResponder(self.window.inputResponder)
        self.windowController = self.window.getWindowController()
        self.windowController.showWindow(self)
        NSApplication.shared.mainMenu = Menu()

        guard self.options.mode != .test else {
            return
        }

        if self.options.mode == .debug {
            let debugger = self.conductor.attach()
            DebuggerWindow(debugger: debugger).getWindowController().showWindow(self)
        }
    }
}
