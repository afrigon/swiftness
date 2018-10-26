//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

protocol LogicLoop: GuardStatus {
    func start(closure: @escaping (Double) -> ())
    func stop()
}
