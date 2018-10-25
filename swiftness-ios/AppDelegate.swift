//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    private var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.tintColor = .blue
        self.window!.backgroundColor = .white
        
        self.window!.rootViewController = ViewController()
        self.window!.makeKeyAndVisible()
        
        return true
    }
}
