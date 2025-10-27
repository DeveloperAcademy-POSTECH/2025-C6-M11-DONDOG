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
    @Published var inviteShowSentHint: Bool = false
    @Published var authShowWithdraw: Bool = false
    @Published var authNumberShowWithdraw: Bool = false
    
    private var notificationToken: NSObjectProtocol?
    var sessionKey: String { Auth.auth().currentUser?.uid ?? "loggedout" }
    
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
        
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let deepLink = appDelegate.initialDeepLink {
                print("저장된 딥링크 처리: \(deepLink)")
                self.handleDeepLink(deepLink)
                
                // 처리 후 중복 실행 방지
                appDelegate.initialDeepLink = nil
            }
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
        case .welcome:
            factory.makeWelcomeView()
        case .auth:
            factory.makeAuthView(isWithDraw: authShowWithdraw)
        case .authNumber:
            factory.makeAuthNumberView(isNumberWithdraw :authNumberShowWithdraw)
        case .profileSetup:
            factory.makeProfileSetupView()
        case .invite:
            factory.makeInviteView(showSentHint: inviteShowSentHint)
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
        case .archive(let roomId):
            factory.makeArchiveView(in: roomId)
                .id(roomId)
        case .archiveDetail(let roomId, let date, let initialPosts):
            factory.makeArchiveDetailView(in: roomId, date: date, initialPosts: initialPosts)
        case .postDetail(let posts, let postType):
            factory.makePostDetailView(with: posts, for: postType)
        }
    }
    
    func handleDeepLink(_ urlString: String) {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              scheme == "dondog" else { return }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // 모든 딥링크는 피드에서 시작
        if root != .feed {
            replaceRoot(.feed)
        } else {
            popToRoot()
        }
        
        switch url.host {
        case "post":
            let roomId = components?.queryItems?.first(where: { $0.name == "roomId" })?.value
            let postId = components?.queryItems?.first(where: { $0.name == "postId" })?.value
            
            if let roomId = roomId, let postId = postId {
                push(.post(postId: postId, roomId: roomId))
            }
            
        default:
            // 처리할 수 없는 host일 경우 피드로 이동
            break
        }
    }
}
