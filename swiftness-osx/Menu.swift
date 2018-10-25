//
//  Created by Alexandre Frigon on 2018-10-24.
//  Copyright © 2018 Frigstudio. All rights reserved.
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
