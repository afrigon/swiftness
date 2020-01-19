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
import nes

class DirectionalPad: UIView {
    var buttonDown: ((Controller.Button) -> Void)!
    var buttonUp: ((Controller.Button) -> Void)!

    private var path = UIBezierPath()
    private var offsetVector: CGPoint = .zero
    private var currentButton: Controller.Button!
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    init() {
        super.init(frame: .zero)

        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        self.clipsToBounds = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.offsetVector = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    }

    override func draw(_ rect: CGRect) {
        self.path = UIBezierPath()
        let glyphWidth: CGFloat = self.bounds.width * 0.25
        let glyphHeight: CGFloat = glyphWidth * 0.54
        let glyphMargin: CGFloat = 2

        // up
        self.path.move(to: CGPoint(x: self.bounds.width / 2 - glyphWidth / 2, y: glyphHeight))
        self.path.addLine(to: CGPoint(x: self.bounds.width / 2, y: glyphMargin))
        self.path.addLine(to: CGPoint(x: self.bounds.width / 2 + glyphWidth / 2, y: glyphHeight))

        // down
        self.path.move(to: CGPoint(x: self.bounds.width / 2 - glyphWidth / 2, y: self.bounds.height - glyphHeight))
        self.path.addLine(to: CGPoint(x: self.bounds.width / 2, y: self.bounds.height - glyphMargin))
        self.path.addLine(to: CGPoint(x: self.bounds.width / 2 + glyphWidth / 2, y: self.bounds.height - glyphHeight))

        // left
        self.path.move(to: CGPoint(x: glyphHeight, y: self.bounds.height / 2 - glyphWidth / 2))
        self.path.addLine(to: CGPoint(x: glyphMargin, y: self.bounds.height / 2))
        self.path.addLine(to: CGPoint(x: glyphHeight, y: self.bounds.height / 2 + glyphWidth / 2))

        // right
        self.path.move(to: CGPoint(x: self.bounds.width - glyphHeight, y: self.bounds.height / 2 - glyphWidth / 2))
        self.path.addLine(to: CGPoint(x: self.bounds.width - glyphMargin, y: self.bounds.height / 2))
        self.path.addLine(to: CGPoint(x: self.bounds.width - glyphHeight, y: self.bounds.height / 2 + glyphWidth / 2))

        self.path.lineWidth = 2
        UIColor(hex: 0xFFFFFF, alpha: 0.6).setStroke()
        self.path.stroke()


        let circleSize: CGFloat = glyphWidth * 0.75
        self.path = UIBezierPath(ovalIn: CGRect(x: self.bounds.width / 2 - circleSize / 2, y: self.bounds.height / 2 - circleSize / 2, width: circleSize, height: circleSize))

        self.path.lineWidth = 2
        UIColor(hex: 0xFFFFFF, alpha: 0.1).setStroke()
        self.path.stroke()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        for touch in touches {
            self.enable(for: touch.location(in: self) - self.offsetVector)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        for touch in touches {
            self.enable(for: touch.location(in: self) - self.offsetVector)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        for touch in touches {
            self.disable(for: touch.location(in: self) - self.offsetVector)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        for touch in touches {
            self.disable(for: touch.location(in: self) - self.offsetVector)
        }
    }

    private func enable(for location: CGPoint) {
        guard self.buttonDown != nil else { return }

        var newButton: Controller.Button!
        if abs(location.x) >= abs(location.y) {
            if location.x >= 0 {
                newButton = .right
            } else {
                newButton = .left
            }
        } else {
            if location.y >= 0 {
                newButton = .down
            } else {
                newButton = .up
            }
        }

        if self.currentButton != nil {
            if newButton == self.currentButton { return }
            self.buttonUp(self.currentButton)
        }

        self.currentButton = newButton
        self.feedback.impactOccurred()
        self.buttonDown(newButton)
    }

    private func disable(for location: CGPoint) {
        guard self.buttonUp != nil else { return }

        if abs(location.x) >= abs(location.y) {
            if location.x >= 0 {
                self.buttonUp(.right)
            } else {
                self.buttonUp(.left)
            }
        } else {
            if location.y >= 0 {
                self.buttonUp(.down)
            } else {
                self.buttonUp(.up)
            }
        }
        
        self.currentButton = nil
    }
}

fileprivate extension CGPoint {
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
