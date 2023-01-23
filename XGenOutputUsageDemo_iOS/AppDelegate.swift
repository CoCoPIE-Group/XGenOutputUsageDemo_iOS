//
//  AppDelegate.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/2.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let homeVC = HomeViewController()
        let navi = UINavigationController(rootViewController: homeVC)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        window?.rootViewController = navi
        window?.makeKeyAndVisible()
        
        return true
    }
}

