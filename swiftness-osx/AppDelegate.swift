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
import nes

class AppDelegate: NSObject, NSApplicationDelegate {
    private var options: StartupOptions!
    var window: ConsoleWindow!

    override init() {
        super.init()
        let arguments = Array(CommandLine.arguments.dropFirst())
        self.options = StartupOptions.parse(arguments)
        guard self.options != nil else { exit(0) }

        self.options.romURL = URL(string: "file:///Users/frigon/Downloads/nes/palette.nes")
        self.options.romURL = URL(string: "file:///Users/frigon/.nes/roms/donkey-kong.nes")
        
        self.options.romURL = URL(string: "file:///Users/frigon/.nes/roms/zelda.nes")
        self.options.romURL = URL(string: "file:///Users/frigon/.nes/roms/lesbian-tennis.nes")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let url = self.options.romURL else {
            print("No url found to load the rom from")
            return
        }

        guard let data = try? Data(contentsOf: url) else {
            print("Could not load data from \(url)")
            return
        }

        guard let rom = NesFile.parse(data: NSData(data: data)) else {
            print("Could not parse input file into a cartridge")
            return
        }


        self.window = ConsoleWindow(NesConsole(rom: rom))

        self.window.title = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Swiftness"
        if let filepath = options.romURL {
            self.window.title += " - \(filepath.lastPathComponent)"
        }

        self.window.windowController?.showWindow(self)
        NSApplication.shared.mainMenu = ConsoleMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        self.window.willTerminate()
    }
}
