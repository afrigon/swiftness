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

protocol BusConnectedComponent {
    func busRead(at address: Word) -> Byte
    func busWrite(_ data: Byte, at address: Word)
}

class Bus {
    weak var delegate: BusDelegate?

    var mirroringMode: ScreenMirroring {
        return self.delegate?.mirroringMode ?? .horizontal
    }

    func triggerInterrupt(of type: InterruptType) {
        guard let delegate = self.delegate else {
            fatalError("A bus delegate must be assign before any interrupt signal is sent over the bus")
        }
        delegate.bus(bus: self, shouldTriggerInterrupt: type)
    }

    func renderFrame(frameBuffer: FrameBuffer) {
        guard let delegate = self.delegate else {
            fatalError("A bus delegate must be assign before frames are sent over the bus")
        }
        delegate.bus(bus: self, shouldRenderFrame: frameBuffer)
    }

    func block(cycles: UInt16) {
        guard let delegate = self.delegate else {
            fatalError("A bus delegate must be assign before using the bus")
        }
        delegate.bus(bus: self, didBlockFor: cycles)
    }

    func readByte(at address: Word, of component: Component? = nil) -> Byte {
        guard let delegate = self.delegate else {
            fatalError("A bus delegate must be assign before any read or write signal is sent over the bus")
        }

        if let component = component {
            return delegate.bus(bus: self, didSendReadSignalAt: address, of: component)
        }

        return delegate.bus(bus: self, didSendReadSignalAt: address)
    }

    func writeByte(_ data: Byte, at address: Word, of component: Component? = nil) {
        guard let delegate = self.delegate else {
            fatalError("A bus delegate must be assign before any read or write signal is sent over the bus")
        }

        if let component = component {
            return delegate.bus(bus: self, didSendWriteSignalAt: address, of: component, data: data)
        }

        delegate.bus(bus: self, didSendWriteSignalAt: address, data: data)
    }
}

protocol BusDelegate: AnyObject {
    var mirroringMode: ScreenMirroring { get }

    func bus(bus: Bus, shouldTriggerInterrupt type: InterruptType)
    func bus(bus: Bus, shouldRenderFrame frameBuffer: FrameBuffer)
    func bus(bus: Bus, didBlockFor cycles: UInt16)
    func bus(bus: Bus, didSendReadSignalAt address: Word) -> Byte
    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte)
    func bus(bus: Bus, didSendReadSignalAt address: Word, of component: Component) -> Byte
    func bus(bus: Bus, didSendWriteSignalAt address: Word, of component: Component, data: Byte)
}
