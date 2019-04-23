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

class AppDelegate: UIResponder, UIApplicationDelegate {
    private var options: StartupOptions!
    var window: UIWindow?

    override init() {
        super.init()
        let arguments = Array(CommandLine.arguments.dropFirst())
        self.options = StartupOptions.parse(arguments)
        guard self.options != nil else { exit(0) }

        guard (try? FileHelper.initDocuments()) != nil else {
            // show could not init files or something
            return
        }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [
                        UIApplication.LaunchOptionsKey: Any
                     ]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.tintColor = .primary
        self.window!.backgroundColor = .darkBlue

        // should be changed for game browser vc
        self.window?.rootViewController = UIViewController()
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        self.options.romURL = url
        
        guard let data = try? FileHelper.open(url: url) else { return false }
        guard let rom = NesFile.parse(data: NSData(data: data)) else { return false }
        guard let vc = ConsoleViewController(NintendoEntertainmentSystem(load: rom)) else { return false }

        self.window?.rootViewController?.present(vc, animated: true, completion: nil)
        return true
    }
}
