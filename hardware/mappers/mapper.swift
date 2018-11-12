//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

enum MapperType: Byte {
    case nrom = 0
    case mmc1 = 1
    case unrom = 2
    case cnrom = 3
    case mmc3 = 4
    case mmc5 = 5
    case ffef4 = 6
    case aorom = 7
    case ffef3 = 8
    case mmc2 = 9
    case mmc4 = 10
    case colordream = 11
    case ffef6 = 12
}

protocol MapperDelegate {
    func mapper(mapper: Mapper, didReadAt address: Word, of region: CartridgeRegion) -> Byte
    func mapper(mapper: Mapper, didWriteAt address: Word, of region: CartridgeRegion, data: Byte)
    func programBankCount(for mapper: Mapper) -> UInt8
}

protocol Mapper: BusConnectedComponent {
    var delegate: MapperDelegate { get set }
    init(_ delegate: MapperDelegate)
}

class MapperFactory {
    static func create(_ type: MapperType, withDelegate delegate: MapperDelegate) -> Mapper {
        switch type {
        case .mmc1: return MemoryManagmentController1(delegate)
        case .mmc3: return MemoryManagmentController3(delegate)
        default:
            fatalError("Mapper (\(String(describing: type).uppercased())) is not implemented")
        }
    }
}
