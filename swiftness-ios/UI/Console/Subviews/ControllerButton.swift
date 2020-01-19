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

class ControllerButton: UIView {
    var buttonDown: ((Controller.Button) -> Void)!
    var buttonUp: ((Controller.Button) -> Void)!

    private let button: Controller.Button
    private let label = UILabel()
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    init(type: Controller.Button) {
        self.button = type
        super.init(frame: .zero)

        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        self.layer.borderColor = UIColor(hex: 0xFFFFFF, alpha: 0.1).cgColor
        self.layer.borderWidth = 2

        self.label.text = String(describing: self.button).uppercased()
        self.label.textColor = UIColor(hex: 0xFFFFFF, alpha: 0.6)
        self.label.font = (self.button == .start || self.button == .select) ?
            UIFont.systemFont(ofSize: 14, weight: .bold) :
            UIFont.systemFont(ofSize: 24, weight: .bold)

        self.addSubview(self.label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.sizeToFit()
        self.label.frame.origin = (self.button == .start || self.button == .select) ?
            CGPoint(x: (self.bounds.width - self.label.bounds.width) / 2, y: -self.label.bounds.height) :
            CGPoint(x: (self.bounds.width - self.label.bounds.width) / 2, y: (self.bounds.height - self.label.bounds.height) / 2)

        self.layer.cornerRadius = self.bounds.height / 2
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard self.buttonDown != nil else { return }
        self.feedback.impactOccurred()
        self.buttonDown(self.button)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard self.buttonUp != nil else { return }
        self.buttonUp(self.button)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard self.buttonUp != nil else { return }
        self.buttonUp(self.button)
    }
}
