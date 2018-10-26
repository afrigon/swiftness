//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    private let renderer = MetalRenderer()
    private let loop = CVDisplayLinkLoop()
    private var conductor: Conductor!
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.addSublayer(self.renderer.layer)
    }
    
    override func viewDidLoad() {
        self.conductor = Conductor(with: self.renderer, drivenBy: self.loop)
    }
}
