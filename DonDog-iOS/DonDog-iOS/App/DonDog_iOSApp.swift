//
//  DonDog_iOSApp.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      
    if FirebaseApp.app() == nil {
          print("❌ [Firebase] Not configured. `FirebaseApp.app()` returned nil.")
    } else {
        print("✅ [Firebase] Configured")
    }

    return true
  }
}

@main
struct DonDog_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            let factory = ModuleFactory.shared
            let coordinator = AppCoordinator(factory: factory)
            RootNavigationView(coordinator: coordinator)
        }
    }
}
