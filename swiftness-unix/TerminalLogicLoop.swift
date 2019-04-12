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

class TerminalLogicLoop: LogicLoop {
    private var closure: ((Double) -> Void)?
    private var shouldExit: Bool = false

    weak var delegate: LogicLoopDelegate?

    func start(closure: @escaping (Double) -> Void) {
        self.closure = closure
    }

    func test() {
        while !self.shouldExit {
            // wat
        }
    }

//    private let source: DispatchSourceUserDataAdd
//    private var timer: CVDisplayLink! = nil
//    private var running : Bool { return CVDisplayLinkIsRunning(self.timer) }
//
//    private var currentTime: Double = CACurrentMediaTime()
//    private var fps: UInt32 = 0
//
//
//    weak var delegate: LogicLoopDelegate?
//
//    var status: String {
//        return " FPS: \(self.fps)"
//    }
//
//    init() {
//        self.source = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.main)
//        let timer = self.createTimer()
//        self.setCGDisplay(timer)
//        self.createCallback(timer)
//    }
//
//    deinit {
//        CVDisplayLinkStop(self.timer)
//        self.source.cancel()
//    }
//
//    func createTimer() -> CVDisplayLink {
//        CVDisplayLinkCreateWithActiveCGDisplays(&self.timer)
//
//        guard self.timer != nil else {
//            fatalError("Could not create link with active display")
//        }
//
//        return timer
//    }
//
//    private func setCGDisplay(_ timer: CVDisplayLink) {
//        let result = CVDisplayLinkSetCurrentCGDisplay(timer, CGMainDisplayID())
//
//        guard result == kCVReturnSuccess else {
//            fatalError("Could not link with current CG display")
//        }
//    }
//
//    private func createCallback(_ timer: CVDisplayLink) {
//        let result = CVDisplayLinkSetOutputCallback(timer, { _, _, _, _, _, sourceUnsafeRaw in
//            if let sourceUnsafeRaw = sourceUnsafeRaw {
//                let sourceUnmanaged = Unmanaged<DispatchSourceUserDataAdd>.fromOpaque(sourceUnsafeRaw)
//                sourceUnmanaged.takeUnretainedValue().add(data: 1)
//            }
//            return kCVReturnSuccess
//        }, Unmanaged.passUnretained(self.source).toOpaque())
//
//        guard result == kCVReturnSuccess else {
//            fatalError("Could not create output callback")
//        }
//
//        self.source.setEventHandler(handler: self.loopClosure)
//    }
//
//    private func loopClosure() {
//        let newTime = CACurrentMediaTime()
//        let deltaTime = newTime - self.currentTime
//        self.currentTime = newTime
//        self.fps = UInt32(1 / deltaTime)
//
//        if let closure = self.closure {
//            closure(deltaTime)
//            self.delegate?.logicLoop(loop: self, didExecuteCallback: deltaTime)
//        }
//    }
//
//    func start(closure: @escaping (Double) -> Void) {
//        self.closure = closure
//        CVDisplayLinkStart(self.timer)
//        self.source.resume()
//    }
}
