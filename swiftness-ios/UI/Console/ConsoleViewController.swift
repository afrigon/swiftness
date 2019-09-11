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

class ConsoleViewController: UIViewController {
    private var conductor: Conductor! = nil
    private var console: Console
    private let loop = CADisplayLinkLoop()
    private let renderer: MetalRenderer! = MetalRenderer()
    private let inputManager = InputResponder()

    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .slide }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return .portrait }

    private var mainView: ConsoleView {
        return self.view as! ConsoleView
    }

    init?(_ console: Console) {
        self.console = console
        super.init(nibName: nil, bundle: nil)

        #if !targetEnvironment(simulator)
        guard self.renderer != nil else { return nil }

        self.conductor = Conductor(use: self.console, drivenBy: self.loop, renderedBy: self.renderer, interactingWith: self.inputManager)
        self.conductor.onUpdate { _ in
            self.view.backgroundColor = UIColor(hex: Int(self.console.mainColor))
        }
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.renderer.layer.frame = self.mainView.gameView.bounds
    }

    override func loadView() {
        super.loadView()
        self.view = ConsoleView(interactingWith: self.inputManager)
        self.mainView.screenRatio = CGFloat(self.console.screenHeight) / CGFloat(self.console.screenWidth)
        self.mainView.gameView.layer.addSublayer(self.renderer.layer)
        self.view.setNeedsLayout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        SaveManager.save(checksum: self.console.checksum, data: self.console.saveRam)
    }
}
