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

    // should have a system to only draw when a new frame is ready to save on host performance
    // or a way to actually push the frame buffer back to the conductor like a vblank delegate or some shit

    private var cycle: UInt16 = 0       // 341 per scanline
    private var scanline: UInt16 = 0    // 262 per frame, 0->239: visible, 240: post, 241->260: vblank, 261: pre

    private var controlRegister: Byte = 0   // 0x2000
    private var maskRegister: Byte = 0      // 0x2001
    private var statusRegister: Byte = 0    // 0x2002

    var status: String {
        return """
        |-------- PPU --------|
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
