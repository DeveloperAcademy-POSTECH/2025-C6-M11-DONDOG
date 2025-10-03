//
//  DonDog_iOSApp.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI

@main
struct DonDog_iOSApp: App {
    
    var body: some Scene {
        WindowGroup {
            let factory = ModuleFactory.shared
            let coordinator = AppCoordinator(factory: factory)
            RootNavigationView(coordinator: coordinator)
        }
    }
}
