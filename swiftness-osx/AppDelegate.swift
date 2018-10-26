//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Alexandre Frigon. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private let scale = 3
    private var window: NSWindow!
    private var viewController: NSViewController!
    
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
        self.window.makeFirstResponder(self.viewController)
    }
}
