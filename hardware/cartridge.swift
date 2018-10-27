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

enum ScreenMirroring {
    case vertical
    case horizontal
    case quad
}

class Cartridge: GuardStatus {
    private let programReadOnlyMemory: [Byte]
    private let characterReadOnlyMemory: [Byte]
    private let saveRandomAccessMemory = [Byte](repeating: 0x00, count: 0x2000)
    private let mapperType: MapperType
    private let mirroring: ScreenMirroring
    private let battery: Bool
    
    var status: String {
        return """
        |-------- ROM --------|
         PRG:  \(self.programReadOnlyMemory.count / 16384)KB   CHR: \(self.characterReadOnlyMemory.count / 8192)KB
         SRAM: \(self.saveRandomAccessMemory.count / 8192)KB   Battery: \(self.battery)
         Mirroring:  \(String(describing: self.mirroring).capitalized)
         Mapper:     \(String(describing: self.mapperType).capitalized)
        """
    }
    
    init(prg: [Byte], chr: [Byte], mapperType: MapperType, mirroring: ScreenMirroring, battery: Bool) {
        self.programReadOnlyMemory = prg
        self.characterReadOnlyMemory = chr
        self.mapperType = mapperType
        self.mirroring = mirroring
        self.battery = battery
    }
}
