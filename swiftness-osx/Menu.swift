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

class Menu: NSMenu, NSMenuItemValidation, NSMenuDelegate {
    init() {
        super.init(title: "Main Menu")

        // swiftness
        let swiftness = NSMenuItem(title: "Swiftness", action: nil, keyEquivalent: "")
        let swiftnessMenu = NSMenu(title: "Swiftness")
        swiftnessMenu.addItem(withTitle: "About Swiftness", action: #selector(self.about), keyEquivalent: "")
        swiftnessMenu.addItem(withTitle: "Quit Swiftness", action: #selector(self.quit), keyEquivalent: "q")
        swiftness.submenu = swiftnessMenu

        // file
        let file = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Open", action: nil, keyEquivalent: "o")
        file.submenu = fileMenu

        self.addItem(swiftness)
        self.addItem(file)
        self.delegate = self
    }

    required init(coder decoder: NSCoder) { super.init(coder: decoder) }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool { return true }

    @objc func about() {
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey.applicationName : "Swiftness"
        ])
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
