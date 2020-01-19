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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var options: StartupOptions!
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        if self.options == nil {
            self.options = StartupOptions.parse([])
            guard self.options != nil else { exit(0) }
        }

        if self.window == nil {
            self.window = UIWindow(windowScene: scene)
            self.window!.tintColor = .primary
            self.window!.backgroundColor = .darkBlue
        }

        // should be changed for game browser vc
        self.window?.rootViewController = UIViewController()
        self.window?.makeKeyAndVisible()

        if let context = connectionOptions.urlContexts.first {
            return self.openURL(url: context.url)
        }
    }

    private func openURL(url: URL) {
        self.options.romURL = url

        guard let data = try? FileHelper.open(url: url) else { return }
        guard let rom = NesFile.parse(data: NSData(data: data)) else { return }

        guard let vc = ConsoleViewController(NesConsole(rom: rom)) else { return }

        vc.modalPresentationStyle = .fullScreen
        self.window?.rootViewController?.present(vc, animated: true, completion: nil)
    }
}
