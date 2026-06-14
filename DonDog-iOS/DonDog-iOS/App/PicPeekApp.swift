//
//  PicPeekApp.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import FirebaseAuth
import SwiftUI

@main
struct PicPeekApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var coordinator = AppCoordinator(factory: ModuleFactory.shared)
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView(coordinator: coordinator)
                .toolbarBackground(.hidden, for: .navigationBar)
                .onOpenURL { url in
                    if Auth.auth().canHandle(url) {
                        return
                    }
                    coordinator.handleDeepLink(url: url)
                }
        }
    }
}
