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

import Foundation

enum NameTableAddress: Word {
    case first = 0x2000
    case second = 0x2400
    case third = 0x2800
    case fourth = 0x2C00
}

class Palette {
    var grayscale: Bool = false
    var emphasisRed: Bool = false
    var emphasisGreen: Bool = false
    var emphasisBlue: Bool = false

    // From http://nesdev.com//NESTechFAQ.htm
    // Item #56: How do I get an accurate palette then?
    private let colors: [DWord] = [
        0x808080, 0x003DA6, 0x0012B0, 0x440096,
        0xA1005E, 0xC70028, 0xBA0600, 0x8C1700,
        0x5C2F00, 0x104500, 0x054A00, 0x00472E,
        0x004166, 0x000000, 0x050505, 0x050505,
        0xC7C7C7, 0x0077FF, 0x2155FF, 0x8237FA,
        0xEB2FB5, 0xFF2950, 0xFF2200, 0xD63200,
        0xC46200, 0x358000, 0x058F00, 0x008A55,
        0x0099CC, 0x212121, 0x090909, 0x090909,
        0xFFFFFF, 0x0FD7FF, 0x69A2FF, 0xD480FF,
        0xFF45F3, 0xFF618B, 0xFF8833, 0xFF9C12,
        0xFABC20, 0x9FE30E, 0x2BF035, 0x0CF0A4,
        0x05FBFF, 0x5E5E5E, 0x0D0D0D, 0x0D0D0D,
        0xFFFFFF, 0xA6FCFF, 0xB3ECFF, 0xDAABEB,
        0xFFA8F9, 0xFFABB3, 0xFFD2B0, 0xFFEFA6,
        0xFFF79C, 0xD7E895, 0xA6EDAF, 0xA2F2DA,
        0x99FFFC, 0xDDDDDD, 0x111111, 0x111111
    ]

    func get(_ index: Int) -> DWord {
        guard index > 0 && index < 52 else { return 0 }

        if self.grayscale {
            return self.colors[Int(floor(Double(index) / 16)) * 16]
        }

        // TODO: handle emphasis modes

        return self.colors[index]
    }
}

class MaskRegister {
    private var value: Byte = 0
    static func &= (left: inout MaskRegister, right: Byte) { left.value = right }

    var greyscale: Bool { return Bool(self.value & 0b00000001) }
    var clipBackground: Bool { return Bool(self.value & 0b00000010) }
    var clipSprites: Bool { return Bool(self.value & 0b00000100) }
    var showBackground: Bool { return Bool(self.value & 0b00001000) }
    var showSprites: Bool { return Bool(self.value & 0b00010000) }
    var emphasisRed: Bool { return Bool(self.value & 0b00100000) }
    var emphasisGreen: Bool { return Bool(self.value & 0b01000000) }
    var emphasisBlue: Bool { return Bool(self.value & 0b10000000) }
}

class PictureProcessingUnit: GuardStatus, BusConnectedComponent {
    private let bus: Bus
    private let cyclePerScanline: UInt16 = 341
    private let scanlinePerFrame: UInt16 = 262

    private var frameBuffers = (
        current: FrameBuffer(width: NintendoEntertainmentSystem.screenWidth,
                             height: NintendoEntertainmentSystem.screenHeight),
        rendered: FrameBuffer(width: NintendoEntertainmentSystem.screenWidth,
                              height: NintendoEntertainmentSystem.screenHeight)
    )

    private var cycle: UInt16 = 0       // 341 per scanline
    private var scanline: UInt16 = 0    // 262 per frame, 0->239: visible, 240: post, 241->260: vblank, 261: pre

    private var controlRegister: Byte = 0       // 0x2000
    private var maskRegister = MaskRegister()   // 0x2001
    private var statusRegister: Byte = 0        // 0x2002

    private let palette = Palette()

    var status: String {
        return """
        |-------- PPU --------|
         Cycle: \(self.cycle)  Scanline: \(self.scanline)
        """
    }

    init(using bus: Bus) {
        self.bus = bus
    }

    func getFrameBuffer() -> FrameBuffer {
        return self.frameBuffers.rendered
    }

    private func normalize(_ address: Word) -> Word {
        return (address - 0x2000) % 8 + 0x2000
    }

    func busRead(at address: Word) -> Byte {
        let address = self.normalize(address)

        switch address {
        case 0x2002:
            let value = self.statusRegister
            self.statusRegister = self.statusRegister & 0b01111111
            return value
        case 0x2000, 0x2001: fallthrough
        default:
            return 0
        }
    }

    func busWrite(_ data: Byte, at address: Word) {
        let address = self.normalize(address)

        switch address {
        case 0x2001:
            self.maskRegister &= data
            self.palette.grayscale = self.maskRegister.greyscale
            self.palette.emphasisRed = self.maskRegister.emphasisRed
            self.palette.emphasisGreen = self.maskRegister.emphasisGreen
            self.palette.emphasisBlue = self.maskRegister.emphasisBlue
        case 0x2002: fallthrough
        default: return
        }
    }

    func step() {
        // cycle logic

        // trigger nmi ?

        self.cycle = (self.cycle + 1) % self.cyclePerScanline
        if self.cycle == 0 {
            self.scanline = (self.scanline + 1) % self.scanlinePerFrame
        }
    }
}
