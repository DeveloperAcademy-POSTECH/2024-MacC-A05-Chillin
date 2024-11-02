//
//  ReazyApp.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI

@main
struct AppView: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 전체 Tint Color 설정
        UIView.appearance().tintColor = UIColor.primary1

        return true
    }
}
