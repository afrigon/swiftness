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
