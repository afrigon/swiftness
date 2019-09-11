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

import Cocoa
//import Combine

class OverlayView: NSView {
 //   @Published var fps: Double = 0

    let fpsLabel = NSTextField()

    init() {
        super.init(frame: .zero)

        self.fpsLabel.textColor = .yellow
        self.fpsLabel.backgroundColor = .none
        self.fpsLabel.font = NSFont(name: "Menlo-Bold", size: 24)
        self.fpsLabel.isBezeled = false
        self.fpsLabel.isEditable = false

//        _ = $fps.sink { fps in
//            self.fpsLabel.stringValue = "\(fps)"
//        }

        self.addSubview(self.fpsLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)

        self.fpsLabel.sizeToFit()
        self.fpsLabel.frame = NSRect(x: self.bounds.width - self.fpsLabel.bounds.width - 20,
                                     y: self.bounds.height - 45,
                                     width: self.fpsLabel.bounds.width,
                                     height: self.fpsLabel.bounds.height)
    }
}
