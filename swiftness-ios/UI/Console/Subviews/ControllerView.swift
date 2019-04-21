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

class ControllerView: UIView {
    let inputResponder: InputResponder

    let buttonA: ControllerButton
    let buttonB: ControllerButton
    let buttonSelect: ControllerButton
    let buttonStart: ControllerButton
    let dpad: DirectionalPad

    init(_ inputResponder: InputResponder) {
        self.inputResponder = inputResponder

        self.buttonA = self.inputResponder.button(for: .a)
        self.buttonB = self.inputResponder.button(for: .b)
        self.buttonSelect = self.inputResponder.button(for: .select)
        self.buttonStart = self.inputResponder.button(for: .start)
        self.dpad = self.inputResponder.directionalPad()
        super.init(frame: .zero)

        self.addSubview(self.buttonA)
        self.addSubview(self.buttonB)
        self.addSubview(self.buttonSelect)
        self.addSubview(self.buttonStart)
        self.addSubview(self.dpad)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let margin: CGFloat = self.bounds.width * 0.05
        let bigButtonSize: CGFloat = (self.bounds.width * 0.5 - 2 * margin) / 2
        let smallButtonSize: CGFloat = bigButtonSize * 0.3

        self.buttonA.frame = CGRect(x: self.bounds.width - margin - bigButtonSize, y: self.bounds.height * 0.4, width: bigButtonSize, height: bigButtonSize)
        self.buttonB.frame = CGRect(x: self.bounds.width - 2 * (margin + bigButtonSize), y: self.bounds.height * 0.4 + bigButtonSize * 0.6, width: bigButtonSize, height: bigButtonSize)

        self.buttonSelect.frame = CGRect(x: self.bounds.width * 0.5 - margin - bigButtonSize, y: self.bounds.height - margin / 2 - smallButtonSize, width: bigButtonSize, height: smallButtonSize)
        self.buttonStart.frame = CGRect(x: self.bounds.width * 0.5 + margin, y: self.bounds.height - margin / 2 - smallButtonSize, width: bigButtonSize, height: smallButtonSize)

//        let dpadSize: CGFloat = self.bounds.height - (self.bounds.height - self.buttonB.frame.origin.y) - 2 * margin
        let dpadSize: CGFloat = self.bounds.width * 0.5 - margin
        self.dpad.frame = CGRect(x: margin, y: 2 * margin, width: dpadSize, height: dpadSize)
    }
}
