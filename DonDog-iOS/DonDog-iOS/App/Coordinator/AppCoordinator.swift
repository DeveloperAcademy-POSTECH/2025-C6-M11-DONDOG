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
    
    // 기본뷰
    @Published var root: AppRoute = .feed
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    init(factory: ModuleFactoryProtocol) {
        self.factory = factory
        configureAuthBasedRouting()
    }
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
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
    
    /// 루트 교체(스택 비우고 루트만 바꾸기)
    func replaceRoot(_ route: AppRoute) {
        path = NavigationPath()   // 스택 완전 초기화
        root = route              // 루트 화면 교체 → Back 없음
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
            factory.makeCameraView()
        case .feed:
            factory.makeFeedView()
        }
    }
}

extension AppCoordinator {
    func configureAuthBasedRouting() {
        applyRouteForUser()
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            self?.applyRouteForUser()
        }
    }

    private func applyRouteForUser() {
        guard let user = Auth.auth().currentUser else {
            replaceRoot(.auth)
            return
        }
        
        let uid = user.uid
        let docRef = Firestore.firestore().collection("Users").document(uid)
        
        docRef.getDocument(source: .server) { [weak self] snapshot, error in
            guard let self = self else { return }
            
            let path = "Users/\(uid)"
            if let snap = snapshot {
                print("🧭 Firestore getDocument → path=\(path) exists=\(snap.exists) fromCache=\(snap.metadata.isFromCache) pendingWrites=\(snap.metadata.hasPendingWrites)")
            } else {
                print("🧭 Firestore getDocument → path=\(path) snapshot=nil")
            }
            
            if let nsError = error as NSError? {
                if nsError.domain == FirestoreErrorDomain,
                   nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
                    print("⚠️ permission-denied: 보안 규칙로 인해 읽기 불가 → profileSetup로 이동")
                } else {
                    print("⚠️ 사용자 문서 조회 오류: \(nsError.localizedDescription) → profileSetup로 이동")
                }
                self.replaceRoot(.profileSetup)
                return
            }
            
            guard let snapshot = snapshot else {
                self.replaceRoot(.profileSetup)
                return
            }
            
            if snapshot.exists {
                self.replaceRoot(.feed)
            } else {
                self.replaceRoot(.profileSetup)
            }
        }
        
        // 프로필 설정 중에는 루트 자동 교체 금지
        if root == .profileSetup { return }
        
    }
}
