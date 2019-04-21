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

class ConsoleMenu: NSMenu, NSMenuDelegate {
    init() {
        super.init(title: "Main Menu")

        // swiftness
        let swiftness = NSMenuItem(title: "Swiftness", action: nil, keyEquivalent: "")
        let swiftnessMenu = NSMenu(title: "Swiftness")
        swiftnessMenu.addItem(withTitle: "About Swiftness", action: #selector(ConsoleMenu.about(_:)), keyEquivalent: "")
        swiftnessMenu.addItem(withTitle: "Quit Swiftness", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        swiftness.submenu = swiftnessMenu

        // file
        let file = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Open", action: nil, keyEquivalent: "o")
        file.submenu = fileMenu

        // tools
        let tools = NSMenuItem(title: "Tools", action: nil, keyEquivalent: "")
        let toolsMenu = NSMenu(title: "Tools")
        toolsMenu.addItem(withTitle: "Debugger", action: #selector(ConsoleMenu.debugger(_:)), keyEquivalent: "d")
        tools.submenu = toolsMenu

        self.addItem(swiftness)
        self.addItem(file)
        self.addItem(tools)
        self.delegate = self

        //for item: NSMenuItem in self.items { item.target = self }
    }

    required init(coder decoder: NSCoder) { super.init(coder: decoder) }

    @objc static func about(_ sender: Any?) {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey.applicationName: "Swiftness"
        ])
    }

    @objc static func debugger(_ sender: Any?) {
//        let width = CGFloat(1080)
//        let height = CGFloat(720)
//
//        guard let screen = NSScreen.main else {
//            fatalError("User has no screen, wtf?!")
//        }
//
//        let frame = CGRect(x: screen.frame.midX - width / 2,
//                           y: screen.frame.midY - height / 2,
//                           width: width,
//                           height: height)
//        let window = NSWindow(contentRect: frame,
//                               styleMask: [.closable, .miniaturizable, .titled, .fullSizeContentView, .resizable],
//                               backing: .buffered,
//                               defer: false)
//        window.title = "Debugger"
//
//        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//
//        let viewController = DebuggerViewController(debugger: delegate.conductor.attach())
//        viewController.view.frame = CGRect(origin: .zero, size: frame.size)
//        viewController.viewDidLayout()
//        window.makeFirstResponder(viewController)
//        window.contentView?.addSubview(viewController.view)
//
//        let windowController = NSWindowController(window: window)
//        windowController.showWindow(nil)
    }
}
