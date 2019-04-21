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
    var _windowController: NSWindowController?
    override var windowController: NSWindowController? {
        get {
            if self._windowController == nil { self._windowController = NSWindowController(window: self) }
            return self._windowController
        }

        set { self._windowController = newValue }
    }

    init(width: CGFloat, height: CGFloat, styleMask style: NSWindow.StyleMask) {
        guard let screen = NSScreen.main else { fatalError("User has no screen, huh?") }

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
}
