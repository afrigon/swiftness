//
//  Created by Alexandre Frigon on 2018-10-26.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

protocol BusConnectedComponent {
    func busRead(at address: Word) -> Byte
    func busWrite(_ data: Byte, at address: Word)
}

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
}

protocol BusDelegate {
    func bus(bus: Bus, didSendReadSignalAt address: Word) -> Byte
    func bus(bus: Bus, didSendWriteSignalAt address: Word, data: Byte)
}
