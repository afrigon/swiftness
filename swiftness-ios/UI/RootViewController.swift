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

class RootViewController: UIViewController {
    private var options: StartupOptions
    private let renderer: MetalRenderer? = MetalRenderer()
    private var loop = CADisplayLinkLoop()
    private var conductor: Conductor!
    private var inputResponder = InputResponder()

    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .slide }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return .portrait }

    private var mainView: RootView {
        return self.view as! RootView
    }

    init(options: StartupOptions) {
        self.options = options
        super.init(nibName: nil, bundle: nil)

        #if !targetEnvironment(simulator)
            if self.renderer != nil {
                self.conductor = Conductor(use: self.options,
                                           with: self.renderer!,
                                           drivenBy: self.loop,
                                           interactingWith: self.inputResponder)

                guard self.conductor != nil else { return }
                self.conductor!.addUpdateClosure { (deltaTime) in
                    self.view.backgroundColor = UIColor(hex: Int(self.conductor!.backgroundColor))
                }
            }
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        if self.renderer != nil {
            self.renderer!.layer.frame = self.mainView.gameView.bounds
        }
    }

    override func loadView() {
        self.view = RootView(interactingWith: self.inputResponder)
        self.mainView.gameView.layer.addSublayer(self.renderer!.layer)
        self.view.setNeedsLayout()
    }
}
