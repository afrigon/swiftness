//
//  Overlay.swift
//  swift-nes
//
//  Created by Alexandre Frigon on 2018-10-24.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

import Cocoa

struct OverlayItems {
    let fps: UInt32
    let nes: NintendoEntertainmentSystem
}

class OverlayLayer: CATextLayer {
    let refreshInterval: CFTimeInterval = 0.5
    var lastUpdate: CFTimeInterval
    
    override init() {
        self.lastUpdate = self.refreshInterval - 0.05
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.lastUpdate = self.refreshInterval - 0.05
        super.init(coder: aDecoder)
    }
    
    func update(items: OverlayItems, _ deltaTime: CFTimeInterval) {
        self.lastUpdate += deltaTime
        if self.lastUpdate >= self.refreshInterval {
            self.lastUpdate = 0.0
            self.string = """
            |------ General ------|
            Fps: \(items.fps)
            
            |-------- CPU --------|
            
            
            |------- Stack -------|
            
            |-------- PPU --------|
            
            
            |-------- APU --------|
            """
        }
    }
}
