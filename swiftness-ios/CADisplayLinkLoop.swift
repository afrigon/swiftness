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

import UIKit

class CADisplayLinkLoop: LogicLoop {
    private var timer: CADisplayLink! = nil

    private var currentTime: Double = CACurrentMediaTime()
    private var fps: UInt32 = 0
    private var closure: ((Double) -> Void)?

    weak var delegate: LogicLoopDelegate?

    var status: String {
        return " FPS: \(self.fps)"
    }

    init() {
        self.timer = CADisplayLink(target: self, selector: #selector(self.loopClosure))
    }

    deinit {
        self.timer.remove(from: .main, forMode: .default)
    }

    @objc private func loopClosure() {
        let newTime = CACurrentMediaTime()
        let deltaTime = newTime - self.currentTime
        self.currentTime = newTime
        self.fps = UInt32(1 / deltaTime)

        if let closure = self.closure {
            closure(deltaTime)
            self.delegate?.logicLoop(loop: self, didExecuteCallback: deltaTime)
        }
    }

    func start(closure: @escaping (Double) -> Void) {
        self.closure = closure
        self.timer.add(to: .main, forMode: .common)
    }
}
