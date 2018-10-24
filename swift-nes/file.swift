//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Alexandre Frigon. All rights reserved.
//

import Foundation

class File {
    static func test() {
        guard let stream = InputStream(fileAtPath: "~/Desktop/zelda.nes") else {
            fatalError("Could not open this file")
        }
    }
}


//if let stream:InputStream = InputStream(fileAtPath: "/Users/pebble8888/hoge.txt") {
//    var buf:[UInt8] = [UInt8](repeating: 0, count: 16)
//    stream.open()
//    while true {
//        let len = stream.read(&buf, maxLength: buf.count)
//        print("len \(len)")
//        for i in 0..<len {
//            print(String(format:"%02x ", buf[i]), terminator: "")
//        }
//        if len < buf.count {
//            break
//        }
//    }
//    stream.close()
//}
