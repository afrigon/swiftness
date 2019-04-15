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

import Foundation

fileprivate enum CycleType {
    case visible, oam, pre, idle

    init(_ value: UInt16) {
        switch value {
        case 1...256: self = .visible
        case 257: self = .oam
        case 321...336: self = .pre
        default: self = .idle
        }
    }
}

fileprivate enum ScanlineType {
    case visible, post, vblank, pre

    init?(_ value: UInt16) {
        switch value {
        case 0...239: self = .visible
        case 240: self = .post
        case 241...260: self = .vblank
        case 261: self = .pre
        default: return nil
        }
    }
}

fileprivate enum DataFetchType {
    case nameTable, attributeTable, lowTile, highTile, flush

    init?(_ value: UInt16) {
        switch value % 8 {
        case 1: self = .nameTable
        case 3: self = .attributeTable
        case 4: self = .lowTile
        case 7: self = .highTile
        case 0: self = .flush
        default: return nil
        }
    }
}

/*fileprivate*/ class Palette {
    var grayscale: Bool = false
    var emphasisRed: Bool = false
    var emphasisGreen: Bool = false
    var emphasisBlue: Bool = false

    // From http://nesdev.com//NESTechFAQ.htm#56
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

    subscript(_ index: Byte) -> DWord {
        get {
            let index = index % 64

            if self.grayscale {
                return self.colors[Int(floor(Double(index) / 16)) * 16]
            }

            // TODO: handle emphasis modes

            return self.colors[index]
        }
    }
}

class ControlRegister { // 0x2000
    var value: Byte = 0
    static func &= (left: inout ControlRegister, right: Byte) { left.value = right }

    var nameTableAddress: Word { return 0x2000 + Word(value & 0b11) * 0x400 }       // 0: 0x2000; 1: 0x2400; 2: 0x2800; 3: 0x2C00
    var increment: Word { return Bool(self.value & 0b00000100) ? 32 : 1 }           // 0: add 1; 1: add 32
    var spritePatternAddress: Word { return Word((value >> 3) & 1) * 0x1000 }       // 0: $0000; 1: $1000; ignored in 8x16 mode
    var backgroundPatternAddress: Word { return Word((value >> 4) & 1) * 0x1000 }   // 0: $0000; 1: $1000
    var spriteSize: Byte { return Bool(self.value & 0b00010000) ? 16 : 8 }          // 0: 8x8; 1: 8x16
    var masterSlave: Bool { return Bool(self.value & 0b01000000) }
    var interruptEnabled: Bool { return Bool(self.value & 0b10000000) }
}

class MaskRegister { // 0x2001
    var value: Byte = 0
    static func &= (left: inout MaskRegister, right: Byte) { left.value = right }

    var greyscale: Bool { return Bool(self.value & 0b00000001) }
    var clipBackground: Bool { return Bool(self.value & 0b00000010) }
    var clipSprites: Bool { return Bool(self.value & 0b00000100) }
    var showBackground: Bool { return Bool(self.value & 0b00001000) }
    var showSprites: Bool { return Bool(self.value & 0b00010000) }
    var emphasisRed: Bool { return Bool(self.value & 0b00100000) }
    var emphasisGreen: Bool { return Bool(self.value & 0b01000000) }
    var emphasisBlue: Bool { return Bool(self.value & 0b10000000) }

    var renderingEnabled: Bool { return self.showBackground || self.showSprites }
}

class StatusRegister { // 0x2002
    var lastWrite: Byte = 0
    var spriteOverflow: Bool = false
    var spriteZeroHit: Bool = false
    var vblank: Bool = false

    var value: Byte {
        defer { self.vblank = false }
        return Byte(self.lastWrite & 0x1F)
            | Byte(self.spriteOverflow) << 5
            | Byte(self.spriteZeroHit) << 6
            | Byte(self.vblank) << 7
    }

    func clear() {
        self.spriteOverflow = false
        self.spriteZeroHit = false
        self.vblank = false
    }
}

class PictureProcessingUnit: BusConnectedComponent {
    private weak var bus: Bus!
    let cyclePerScanline: UInt16 = 341
    let scanlinePerFrame: UInt16 = 262

    var cycle: UInt16 = 0 // private
    private var _scanline: UInt16 = 0
    private var _frame: Int64 = 0
    var scanline: UInt16 { get { return self._scanline } }
    var frame: Int64 { get { return self._frame } }

    var vramPointer: Word = 0 // private
    private var vramTempPointer: Word = 0
    private var writeToggle: Byte = 0
    private var fineX: Byte = 0
    private var vramBufferedData: Byte = 0

    private var oamPointer: Byte = 0

    var controlRegister = ControlRegister() // private
    var maskRegister = MaskRegister() // private
    var statusRegister = StatusRegister() // private

    private let palette = Palette()
    /*private*/ var paletteIndices = [Byte](repeating: 0x00, count: 32)
    private var nameTable = [Byte](repeating: 0x00, count: 2048)
    private var oam = [Byte](repeating: 0x00, count: 256)

    private var nameTableBuffer: Byte = 0
    private var attributeTableBuffer: Byte = 0
    private var lowTileBuffer: Byte = 0
    private var highTileBuffer: Byte = 0
    private var shiftRegister: UInt64 = 0

    private var frameBuffers = (rendered: FrameBuffer(), current: FrameBuffer())
    var frameBuffer: FrameBuffer { return self.frameBuffers.rendered }

    init(using bus: Bus) { self.bus = bus }

    private func normalize(_ address: Word) -> Word {
        if address >= 0x4000 { return address }
        return (address - 0x2000) % 8 + 0x2000
    }

    func busRead(at address: Word) -> Byte {
        let address = self.normalize(address)

        switch address {
        case 0x2002:
            self.vramTempPointer = 0
            return self.statusRegister.value
        case 0x2004:
            return self.oam[self.oamPointer]
        case 0x2007:
            defer {
                self.vramBufferedData = self.vramRead(at: address)
                self.vramPointer += self.controlRegister.increment
            }
            if self.vramPointer >= 0x3F00 { return self.vramRead(at: self.vramPointer) }
            return self.vramBufferedData
        default: return 0
        }
    }

    func busWrite(_ data: Byte, at address: Word) {
        let address = self.normalize(address)
        self.statusRegister.lastWrite = data

        switch address {
        case 0x2000: self.controlRegister &= data
        case 0x2001:
            self.maskRegister &= data
            self.palette.grayscale = self.maskRegister.greyscale
            self.palette.emphasisRed = self.maskRegister.emphasisRed
            self.palette.emphasisGreen = self.maskRegister.emphasisGreen
            self.palette.emphasisBlue = self.maskRegister.emphasisBlue
        case 0x2003: self.oamPointer = data
        case 0x2004:
            self.oam[self.oamPointer] = data
            self.oamPointer++
        case 0x2005:
            if Bool(self.writeToggle) {
                self.vramTempPointer = (self.vramTempPointer & 0x8FFF) | ((Word(data) & 0x07) << 12)
                self.vramTempPointer = (self.vramTempPointer & 0xFC1F) | ((Word(data) & 0xF8) << 2)
                self.writeToggle = 0
            } else {
                self.vramTempPointer = (self.vramTempPointer & 0xFFE0) | Word(data) >> 3
                self.fineX = data & 0x07
                self.writeToggle = 1
            }
        case 0x2006:
            if Bool(self.writeToggle) {
                self.vramTempPointer = (self.vramTempPointer & 0xFF00) | Word(data)
                self.vramPointer = self.vramTempPointer
                self.writeToggle = 0
            } else {
                self.vramTempPointer = (self.vramTempPointer & 0x80FF) | ((Word(data) & 0x3F) << 8)
                self.writeToggle = 1
            }
        case 0x2007:
            self.vramWrite(data, at: self.vramPointer)
            self.vramPointer += self.controlRegister.increment
        case 0x4014:
            for i: UInt16 in 0..<256 {
                self.oam[self.oamPointer] = self.bus.readByte(at: Word(data) << 8 | i)
                self.oamPointer++
            }
            self.bus.block(cycles: 513)
        default: return
        }
    }

    /*private*/ func vramRead(at address: Word) -> Byte {
        let address: Word = address % 0x4000
        switch address {
        case 0..<0x2000: return self.bus.readByte(at: address, of: .cartridge)
        case 0x2000..<0x3F00: return self.nameTable[address % 2048] // handle mirroring stuff
        case 0x3F00..<0x4000: return self.paletteIndices[address % 32]
        default: return 0
        }
    }

    private func vramWrite(_ data: Byte, at address: Word) {
        let address: Word = address % 0x4000
        switch address {
        case 0..<0x2000: self.bus.writeByte(data, at: address, of: .cartridge)
        case 0x2000..<0x3F00: self.nameTable[address % 2048] = data
        case 0x3F00..<0x4000: self.paletteIndices[address % 32] = data
        default: return
        }
    }

    private func verticalBlank() {
        // Swap buffers and render, TODO: make sure this is a constant time operation aka just swaping pointers
        self.frameBuffers = (current: self.frameBuffers.rendered,
                             rendered: self.frameBuffers.current)
        self.bus.renderFrame(frameBuffer: self.frameBuffers.rendered)
        self.statusRegister.vblank = true

        if self.controlRegister.interruptEnabled {
            self.bus.triggerInterrupt(of: .nmi)
        }
    }

    // inc hori(v)
    private func incrementX() {
        if self.vramPointer & 0x001F == 31 {
            // set coarse x to 0 and switch horizontal nametable
            self.vramPointer &= 0xFFE0
            self.vramPointer ^= 0x0400
        } else {
            self.vramPointer++
        }
    }

    // inc vert(v)
    private func incrementY() {
        // if fine Y < 7
        if self.vramPointer & 0x7000 != 0x7000 {
            self.vramPointer += 0x1000 // inc fine y
        } else {
            self.vramPointer &= 0x8FFF // fine y = 0

            var coarseY = (self.vramPointer & 0x03E0) >> 5
            if coarseY == 29 {
                coarseY = 0
                self.vramPointer ^= 0x0800 // switch vertical nametable
            } else if coarseY == 31 {
                coarseY = 0
            } else {
                coarseY++
            }
            self.vramPointer = (self.vramPointer & 0xFC1F) | (coarseY << 5)
        }
    }

    // hori(v) = hori(t)
    private func copyX() {
        self.vramPointer = (self.vramPointer & 0xFBE0) | (self.vramTempPointer & 0x041F)
    }

    // vert(v) = vert(t)
    private func copyY() {
        self.vramPointer = (self.vramPointer & 0x841F) | (self.vramTempPointer & 0x7BE0)
    }

    private func fetchData(type: DataFetchType?) {
        guard let type = type else { return }

        switch type {
        case .nameTable:
            let address: Word = 0x2000 | (self.vramPointer & 0x0FFF)
            self.nameTableBuffer = self.vramRead(at: address)
        case .attributeTable:
            let address: Word = 0x23C0 | self.vramPointer & 0x0C00 | self.vramPointer >> 4 & 0x38 | self.vramPointer >> 2 & 0x07
            let shift: Word = self.vramPointer >> 4 & 4 | self.vramPointer & 2
            self.attributeTableBuffer = self.vramRead(at: address) >> shift & 3
        case .lowTile:
            let fineY: Word = self.vramPointer >> 12 & 7
            let address: Word = self.controlRegister.backgroundPatternAddress + Word(self.nameTableBuffer) * 16 + fineY
            self.lowTileBuffer = self.vramRead(at: address)
        case .highTile:
            let fineY: Word = self.vramPointer >> 12 & 7
            let address: Word = self.controlRegister.backgroundPatternAddress + Word(self.nameTableBuffer) * 16 + fineY
            self.highTileBuffer = self.vramRead(at: address + 8)
        case .flush:
            var data: DWord = 0
            let a = self.attributeTableBuffer << 2
            for _ in 0..<8 {
                let lo = (self.lowTileBuffer & 0x80) >> 7
                let hi = (self.highTileBuffer & 0x80) >> 6
                self.lowTileBuffer <<= 1
                self.highTileBuffer <<= 1
                data <<= 4
                data |= DWord(a | hi | lo)
            }
            self.shiftRegister |= QWord(data)
            self.incrementX()
        }
    }

    private func render(x: UInt16, y: UInt16) {
        var background: Byte = 0
        if self.maskRegister.showBackground {
            background = Byte((self.shiftRegister >> 32) >> ((7 - self.fineX) * 4) & 0x0F)
        }

        let paletteIndex: Byte = self.paletteIndices[background]
        let color: DWord = self.palette[paletteIndex]
        self.frameBuffers.current.set(x: Int(x), y: Int(y), color: color)
    }

    func step() {
        let scanlineType = ScanlineType(self._scanline)!
        let cycleType = CycleType(self.cycle)

        switch (scanlineType, cycleType) {
        case (.visible, .visible) where self.maskRegister.renderingEnabled:
            self.render(x: self.cycle - 1, y: self._scanline)
            self.shiftRegister <<= 4
            self.fetchData(type: DataFetchType(self.cycle))

        case (.pre, .visible) where self.maskRegister.renderingEnabled:
            self.fetchData(type: DataFetchType(self.cycle))

        case (.pre, .pre) where self.maskRegister.renderingEnabled:
            self.fetchData(type: DataFetchType(self.cycle))

        case (.vblank, _) where self._scanline == 241 && self.cycle == 1:
            self.verticalBlank()

        case (.pre, _) where self.cycle == 1:
            self.statusRegister.clear()
        default: break
        }

        if self.maskRegister.renderingEnabled {
            if scanlineType == .pre && self.cycle >= 280 && self.cycle <= 304 { self.copyY() }
            if scanlineType == .pre || scanlineType == .visible {
                if self.cycle == 256 { self.incrementY() }
                if self.cycle == 257 { self.copyX() }
            }
        }

        // sprite stuff

        self.cycle = (self.cycle + 1) % self.cyclePerScanline
        if self.cycle == 0 {
            self._scanline = (self._scanline + 1) % self.scanlinePerFrame

            if self._scanline == 0 {
                // skipping idle cycle on odd frames
                if self._frame % 2 != 0 { self.cycle++ }
                self._frame &+= 1
            }
        }
    }

    func reset() {
        self.cycle = 321
        self._scanline = 261
        self._frame = -1
        self.controlRegister &= 0
        self.maskRegister &= 0
        self.oamPointer = 0

        self.frameBuffers = (rendered: FrameBuffer(), current: FrameBuffer())
        self.bus.renderFrame(frameBuffer: self.frameBuffers.rendered)
    }
}
