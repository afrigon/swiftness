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

class ConsoleView: UIView {
    private let controllerView: ControllerView!
    let gameView = UIView()
    var screenRatio: CGFloat = 1

    init(interactingWith inputResponder: InputResponder) {
        self.controllerView = ControllerView(inputResponder)
        super.init(frame: .zero)

        self.addSubview(self.gameView)
        self.addSubview(self.controllerView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.frame = UIScreen.main.bounds

        self.gameView.frame = CGRect(x: 0, y: self.safeAreaInsets.top, width: self.bounds.width, height: self.bounds.width * self.screenRatio)
        self.controllerView.frame = CGRect(x: 0, y: self.gameView.bounds.maxY + self.safeAreaInsets.top, width: self.bounds.width, height: self.bounds.height - self.gameView.bounds.maxY - self.safeAreaInsets.top - self.safeAreaInsets.bottom)
    }
}
