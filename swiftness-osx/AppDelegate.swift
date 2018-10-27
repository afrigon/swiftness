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

class AppDelegate: NSObject, NSApplicationDelegate {
    private let scale = 3
    private var window: NSWindow!
    private var viewController: ViewController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let width = CGFloat(256 * self.scale)
        let height = CGFloat(240 * self.scale)
        
        guard let screen = NSScreen.main else {
            fatalError("User has no screen, wtf?!")
        }
        
        let frame = CGRect(x: screen.frame.midX - width / 2,
                           y: screen.frame.midY - height / 2,
                           width: width,
                           height: height)
        self.window = NSWindow(contentRect: frame, styleMask: [.closable, .miniaturizable, .titled], backing: .buffered, defer: false)
        self.window.title = "Swiftness"
        
        self.viewController = ViewController()
        self.viewController.view.frame = CGRect(origin: .zero, size: frame.size)
        self.window.contentView?.addSubview(self.viewController.view)
        
        NSApplication.shared.mainMenu = Menu()
        self.window.makeKeyAndOrderFront(nil)
        self.window.makeFirstResponder(self.viewController.inputResponder)
    }
}
