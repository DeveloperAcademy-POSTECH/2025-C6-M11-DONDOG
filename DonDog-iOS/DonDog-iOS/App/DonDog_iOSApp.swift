//
//  DonDog_iOSApp.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI
import FirebaseAuth

@main
struct DonDog_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            let factory = ModuleFactory.shared
            let coordinator = AppCoordinator(factory: factory)
            RootNavigationView(coordinator: coordinator)
                .onOpenURL { url in
                    _ = Auth.auth().canHandle(url)
                }
        }
    }
}
