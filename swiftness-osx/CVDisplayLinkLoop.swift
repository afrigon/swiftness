//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

import Cocoa

class CVDisplayLinkLoop: LogicLoop {
    private var currentTime: Double = CACurrentMediaTime()
    private var fps: UInt32 = 0
    private var closure: ((Double) -> ())!
    
    var status: String {
        return "FPS: \(self.fps)"
    }
    
    func start(closure: @escaping (Double) -> ()) {
        self.closure = closure
    }
    
    func stop() {
        
    }
}
