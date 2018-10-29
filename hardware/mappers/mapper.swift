//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

enum MapperType: Byte {
    case mmc1 = 1
    case mmc3 = 4
}

protocol MapperDelegate {
    func mapper(mapper: Mapper, didReadAt address: Word, of region: CartridgeRegion) -> Byte
    func mapper(mapper: Mapper, didWriteAt address: Word, of region: CartridgeRegion, data: Byte)
}

protocol Mapper: BusConnectedComponent {
    var delegate: MapperDelegate? { get set }
}

class MapperFactory {
    static func create(_ type: MapperType) -> Mapper {
        switch type {
        case .mmc1: return MemoryManagmentController1()
        case .mmc3: return MemoryManagmentController3()
        }
    }
}
