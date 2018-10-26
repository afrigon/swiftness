//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

class RandomAccessMemory: BusConnectedComponent, GuardStatus {
    private var data: [Byte]
    let addressRange: Range<Word> = 0x0000..<0x2000
    let size: Word = 0x0800 // Bytes
    
    var status: String {
        return ""
    }
    
    init() {
        self.data = Array(repeating: 0x00, count: Int(self.size))
    }
    
    func busRead(at address: Word) -> Byte {
        guard self.addressRange.contains(address) else {
            fatalError("RAM access restriction violation")
        }
        return self.data[address % self.size]
    }
    
    func busWrite(_ data: Byte, at address: Word) {
        guard self.addressRange.contains(address) else {
            fatalError("RAM access restriction violation")
        }
        self.data[address % self.size] = data
    }
}
