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

class Channel {
    var length: Byte = 0

    var _enabled: Bool = false
    var enabled: Bool {
        get { return self._enabled }
        set {
            self._enabled = newValue
            self.length = self._enabled ? self.length : 0
        }
    }
}

class Oscillator: Channel { }

class PulseOscillator: Oscillator { }

class TriangleOscillator: Oscillator { }

class NoiseOscillator: Oscillator { }

class DeltaModulationChannel: Channel { }

class AudioProcessingUnit: BusConnectedComponent {
    private let pulse1 = PulseOscillator()
    private let pulse2 = PulseOscillator()
    private let triangle = TriangleOscillator()
    private let noise = NoiseOscillator()
    private let delta = DeltaModulationChannel()

    func step() {

    }

    func busRead(at address: Word) -> Byte {
        return 0
    }

    func busWrite(_ data: Byte, at address: Word) {
        switch address {
        case 0x4015:
            self.pulse1.enabled = Bool(data & 1)
            self.pulse2.enabled = Bool(data & 2)
            self.triangle.enabled = Bool(data & 4)
            self.noise.enabled = Bool(data & 8)
            self.delta.enabled = Bool(data & 16)
            // maybe restart dmc
        default: return
        }
    }
}
