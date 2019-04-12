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

enum RunMode {
    case debug      // step cpu cycle manually
    case test       // unit tests
    case normal     // as expected
}

class StartupOptions {
    var mode: RunMode = .normal
    var filepath: String?

    static func parse(_ arguments: [String]) -> StartupOptions? {
        let options = StartupOptions()
        var temp: String?

        for argument in arguments {
            switch argument {
            case "-h", "--help", "-help", "help": StartupOptions.printUsage(); return nil
            case "-d", "--debug": options.mode = .debug
            case "-t", "--test": options.mode = .test
            default:
                if argument.hasPrefix("-") {
                    temp = argument
                    continue
                }

                guard let option = temp else {
                    options.filepath = argument
                    continue
                }

                switch option {
                default: continue
                }
            }
        }

        return options
    }

    static func printUsage() {
        print("USAGE: swiftness <options> [gamepath]")
    }
}
