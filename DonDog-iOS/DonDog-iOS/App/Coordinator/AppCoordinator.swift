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
    
    private var lastHandledDeepLink: String?
    private var lastHandledAt: Date?

    private var notificationToken: NSObjectProtocol?
    
    init(factory: ModuleFactoryProtocol, authService: AuthService = AuthService()) {
        self.factory = factory
        self.authService = authService
        authService.configureAuthBasedRouting(coordinator: self)
        
        notificationToken = NotificationCenter.default.addObserver(
            forName: .openDeepLink,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let self,
                let deeplink = note.object as? String
            else { return }
            self.handleDeepLink(deeplink)
        }
    }
    
    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
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
        case .post(let postId, let roomId):
            factory.makePostView(with: postId, in: roomId)
        case .setting:
            factory.makeSettingView()
        case .editprofile:
            factory.makeEditProfileView()

        }
    }
    
    func handleDeepLink(_ urlString: String) {
        // 같은 딥링크가 1.5초 내 재발신되면 무시 (알림 중복 탭/브로드캐스트 중복 방지)
        if lastHandledDeepLink == urlString,
           let last = lastHandledAt,
           Date().timeIntervalSince(last) < 1.5 {
            return
        }

        guard let url = URL(string: urlString) else { return }
        let parts = url.pathComponents.filter { $0 != "/" }

        guard parts.count >= 2, parts[0] == "rooms" else { return }
        let roomId = parts[1]

        // 항상 피드로 루트 정렬 후 목적지로 이동
        if root != .feed {
            replaceRoot(.feed)
        } else {
            // 루트가 .feed여도 스택 초기화
            popToRoot()
        }

        if parts.count >= 4, parts[2] == "posts" {
            let postId = parts[3]
            push(.post(postId: postId, roomId: roomId))
        } else {
            push(.feed)
        }

        // 중복 처리 방지
        lastHandledDeepLink = urlString
        lastHandledAt = Date()
    }
}
