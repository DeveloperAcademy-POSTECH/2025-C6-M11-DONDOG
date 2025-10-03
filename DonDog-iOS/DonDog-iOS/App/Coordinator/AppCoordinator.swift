//
//  AppCoordinator.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI
import Combine

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    private let factory: ModuleFactoryProtocol
    
    init(factory: ModuleFactoryProtocol) {
        self.factory = factory
    }
    
    /// push : 다음 화면으로 넘어갈 때 사용하는 메서드 (_ route 부분에 전환하고자 하는 다음 화면 명시)
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    /// pop : 이전 화면으로 돌아갈 때 사용하는 메서드
    func pop() {
        path.removeLast()
    }
    
    /// popToRoot : path에 쌓여있는 모든 화면을 지우고, 루트로 돌아가도록 하는 메서드
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    @ViewBuilder
    func build(_ route: AppRoute) -> some View {
        switch route {
        case .auth:
            factory.makeAuthView()
        case .invite:
            factory.makeInviteView()
        case .camera:
            factory.makeCameraView()
        case .feed:
            factory.makeFeedView()
        }
    }
}

