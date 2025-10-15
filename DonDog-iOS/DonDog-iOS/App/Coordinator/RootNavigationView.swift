//
//  RootNavigationView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI

struct RootNavigationView: View {
    @StateObject var coordinator: AppCoordinator
    @State private var showMainView = false
    
    init(coordinator: AppCoordinator) {
        self._coordinator = StateObject(wrappedValue: coordinator)
    }
    
    var body: some View {
        ZStack {
            if showMainView {
                NavigationStack(path: $coordinator.path) {
                    coordinator.build(coordinator.root)
                        .navigationDestination(for: AppRoute.self) { route in
                            coordinator.build(route)
                        }
                }
                .environmentObject(coordinator)
            } else {
                SplashView()
                    .task {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showMainView = true
                            }
                        }
                    }
            }
        }
    }
}
