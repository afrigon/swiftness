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

protocol BusConnectedComponent {
    func busRead(at address: Word) -> Byte
    func busWrite(_ data: Byte, at address: Word)
}

//class NullComponent: BusConnectedComponent {
//    func busRead(at address: Word) -> Byte { return 0x00 }
//    func busWrite(_ data: Byte, at address: Word) {
//        fatalError("Illegal write address: \(address)")
//    }
//}

class Bus {
    var delegate: BusDelegate?

    func readByte(at address: Word) -> Byte {
        guard let delegate = self.delegate else {
            fatalError("A bus delegate must be assign before any read or write signal is sent over the bus")
        }
        return delegate.bus(bus: self, didSendReadSignalAt: address)
    }

    func writeByte(_ data: Byte, at address: Word) {
        guard let delegate = self.delegate else {
            fatalError("A bus delegate must be assign before any read or write signal is sent over the bus")
        }
        delegate.bus(bus: self, didSendWriteSignalAt: address, data: data)
    }

    static func testsInstance() -> Bus {
        let bus = Bus()
        bus.delegate = TestsBusDelegate()
        return bus
    }
}

protocol BusDelegate: AnyObject {
    func bus(bus: Bus, didSendReadSignalAt address: Word) -> Byte
    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte)
}

class TestsBusDelegate: BusDelegate {
    func bus(bus: Bus, didSendReadSignalAt address: Word) -> Byte { return 0x40 }
    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte) {}
}
