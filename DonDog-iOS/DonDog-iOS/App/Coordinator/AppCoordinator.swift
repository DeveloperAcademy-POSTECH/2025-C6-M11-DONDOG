//
//  AppCoordinator.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    private let factory: ModuleFactoryProtocol
    private let authService: AuthService
    
    // 기본뷰
    @Published var root: AppRoute = .feed
    
    init(factory: ModuleFactoryProtocol, authService: AuthService = AuthService()) {
        self.factory = factory
        self.authService = authService
        authService.configureAuthBasedRouting(coordinator: self)
    }
    
    /// push : 다음 화면으로 넘어갈 때 사용하는 메서드 (_ route 부분에 전환하고자 하는 다음 화면 명시)
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    /// pop : 이전 화면으로 돌아갈 때 사용하는 메서드
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    /// popToRoot : path에 쌓여있는 모든 화면을 지우고, 루트로 돌아가도록 하는 메서드
    func popToRoot() {
        guard !path.isEmpty else { return }
        path.removeLast(path.count)
    }
    
    /// replaceRoot: path에 쌓인 모든 화면을 지우고, 지정한 route 화면을 새로운 루트 화면으로 교체하는 메서드 (_ route 부분에 가고자 하는 화면 명시)
    func replaceRoot(_ route: AppRoute) {
        path = NavigationPath()   // 스택 완전 초기화
        root = route              // 루트 화면 교체 (뒤로가기 없음)
    }
    
    @ViewBuilder
    func build(_ route: AppRoute) -> some View {
        switch route {
        case .auth:
            factory.makeAuthView()
        case .profileSetup:
            factory.makeProfileSetupView()
        case .invite:
            factory.makeInviteView()
        case .camera:
            EmptyView()
        case .feed:
            factory.makeFeedView()
        case .post:
            factory.makePostView()
        }
    }
}
