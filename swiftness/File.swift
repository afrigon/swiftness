//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Alexandre Frigon. All rights reserved.
//

import Foundation

// not tested
class File {
    static func readBytes(from filePath: String) -> [UInt8]? {
        guard let data = NSData(contentsOfFile: filePath) else { return nil }
        
        var buffer = Array(repeating: UInt8(0x00), count: data.length)
        data.getBytes(&buffer, length: data.length)
        return buffer
    }
    
    static func writeBytes(_ buffer: inout [UInt8], to filepath: String) -> Bool {
        return (try? NSData(bytes: &buffer, length: buffer.count).write(toFile: filepath, options: [])) != nil
    }
}
