//
//  Created by Jose Canepa on 8/18/16.
//  Edited by Alexandre Frigon on 10/15/18.
//  Copyright © 2016 Jose Canepa. All rights reserved.
//

import AppKit

class DisplayLink {
    let timer  : CVDisplayLink
    let source : DispatchSourceUserDataAdd
    var callback : Optional<() -> ()> = nil
    var running : Bool { return CVDisplayLinkIsRunning(timer) }
    
    init?(onQueue queue: DispatchQueue = DispatchQueue.main) {
        self.source = DispatchSource.makeUserDataAddSource(queue: queue)
        var timerRef : CVDisplayLink? = nil
        var successLink = CVDisplayLinkCreateWithActiveCGDisplays(&timerRef)
        
        guard let timer = timerRef else {
            NSLog("Failed to create timer with active display")
            return nil
        }
        
        successLink = CVDisplayLinkSetOutputCallback(timer, { timer, currentTime, outputTime, _, _, sourceUnsafeRaw in
            if let sourceUnsafeRaw = sourceUnsafeRaw {
                let sourceUnmanaged = Unmanaged<DispatchSourceUserDataAdd>.fromOpaque(sourceUnsafeRaw)
                sourceUnmanaged.takeUnretainedValue().add(data: 1)
            }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self.source).toOpaque())
        guard successLink == kCVReturnSuccess else {
            NSLog("Failed to create timer with active display")
            return nil
        }
        
        successLink = CVDisplayLinkSetCurrentCGDisplay(timer, CGMainDisplayID())
        guard successLink == kCVReturnSuccess else {
            NSLog("Failed to connect to display")
            return nil
        }
        
        self.timer = timer
        
    }
    
    deinit { if self.running { self.suspend() } }
    
    public func start() {
        guard !self.running else { return }
        CVDisplayLinkStart(self.timer)
        self.source.resume()
    }
    
    public func suspend() {
        guard self.running else { return }
        CVDisplayLinkStop(self.timer)
        self.source.suspend()
    }
}
