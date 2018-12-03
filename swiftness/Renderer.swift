//
//    MIT License
//
//    Copyright (c) 2018 Alexandre Frigon
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

class FrameBuffer {
    var data: [Byte]
    var size: (width: Int, height: Int)

    init(width: Int, height: Int) {
        self.size = (width, height)
        self.data = [Byte](repeating: 0, count: 4 * width * height)
    }

    func set(x: Int, y: Int, color: DWord = 0x000000) {
        if x < 0 || y < 0 || x >= self.size.width || y >= self.size.height {
            print("invalid write to framebuffer at (\(x), \(y)) with color #\(color.hex())")
            return
        }

        let index = y * self.size.width * 4 + x * 4
        self.data[index] = Byte(color >> 16)
        self.data[index + 1] = Byte((color >> 8) & 0xFF)
        self.data[index + 2] = Byte(color & 0xFF)
        self.data[index + 3] = 0xFF
    }
}

protocol Renderer {
    func draw(_ image: FrameBuffer)
}
