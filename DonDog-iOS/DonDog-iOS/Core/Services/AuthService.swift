//
//  AuthService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/5/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension Notification.Name {
    static let authServiceReconfigureRouting = Notification.Name("AuthService.ReconfigureRouting")
}

final class AuthService {
    static var isAccountDeletionInProgress: Bool = false
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userDocListenr: ListenerRegistration?
    private var reconfigureObserver: NSObjectProtocol?
    private weak var coordinatorRef: AppCoordinator?
    
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        if let listener = userDocListenr {
            listener.remove()
        }
        if let obs = reconfigureObserver { NotificationCenter.default.removeObserver(obs) }
    }
    
    func configureAuthBasedRouting(coordinator: AppCoordinator) {
        self.coordinatorRef = coordinator
        applyRouteForUser(coordinator: coordinator)
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            guard let self = self else { return }
            self.applyRouteForUser(coordinator: coordinator)
        }
        if reconfigureObserver == nil {
            reconfigureObserver = NotificationCenter.default.addObserver(forName: .authServiceReconfigureRouting, object: nil, queue: .main) { [weak self] _ in
                guard let self = self, let coord = self.coordinatorRef else { return }
                self.applyRouteForUser(coordinator: coord)
            }
        }
    }
    
    private func applyRouteForUser(coordinator: AppCoordinator) {
        func replaceRootinAuthService(_ route: AppRoute, coordinator: AppCoordinator) {
            Task { @MainActor in
                if coordinator.root == route { return }
                coordinator.replaceRoot(route)
                
                print("[AuthService replaceRootinAuthService함수] 🔄 \(coordinator.root) → \(route)")
            }
        }
        
        guard let user = Auth.auth().currentUser else {
            Task { @MainActor in
                ConnectStateService.shared.reset()
            }
            replaceRootinAuthService(.welcome, coordinator: coordinator)
            self.userDocListenr?.remove()
            self.userDocListenr = nil
            print("[AuthService] currentUser 없음 → welcome 화면으로 이동")
            return
        }
        
        if AuthService.isAccountDeletionInProgress {
            return
        }
        
        user.getIDTokenResult(forcingRefresh: true) { _, _ in
            /// 로그인 안됨 -> welcome으로 이동
            guard let refresehUser = Auth.auth().currentUser else {
                Task { @MainActor in
                    ConnectStateService.shared.reset()
                }
                replaceRootinAuthService(.welcome, coordinator: coordinator)
                print("[AuthService] IDToken 분실로 current User 찾을 수 없음 → welcome 화면으로 이동")
                return
            }
            
            Task { @MainActor in
                ConnectStateService.shared.reset()
            }
            let uid = refresehUser.uid
            let userDoc = Firestore.firestore().collection("Users").document(uid)
            
            self.userDocListenr?.remove()
            self.userDocListenr = userDoc.addSnapshotListener(includeMetadataChanges: true) { userDoc, error in
                
                /// 계정 삭제 중일 때 (탈퇴) -> welcome으로 이동
                if AuthService.isAccountDeletionInProgress {
                    return
                }
                
                /// 에러 또는 스냅샷 nil 통합 처리
                guard error == nil, let userDoc = userDoc else {
                    if let nsError = error as NSError? {
                        print("⚠️ 사용자 문서 조회 오류: \(nsError.localizedDescription) → welcome로 이동")
                        Task { @MainActor in
                            ConnectStateService.shared.reset()
                        }
                        replaceRootinAuthService(.welcome, coordinator: coordinator)
                    } else {
                        // 오류는 없지만 스냅샷이 nil인 경우: profileSetup으로 이동
                        Task { @MainActor in
                            ConnectStateService.shared.reset()
                        }
                        replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                    }
                    return
                }
                
                /// user 문서가 없을때 (가입 후 프로필 미완성) -> profileSetup
                if userDoc.exists == false {
                    Task { @MainActor in
                        ConnectStateService.shared.reset()
                    }
                    replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                    return
                }
                
                /// 보류 중 쓰기 -> 대기
                if userDoc.metadata.hasPendingWrites {
                    return
                }

                /// user 문서가 있을 때 -> feed로 이동
                let data = userDoc.data() ?? [:]
                let roomId = data["roomId"] as? String
                Task { @MainActor in
                    ConnectStateService.shared.roomId = roomId
                    ConnectStateService.shared.isConnected = (roomId?.isEmpty == false)
                    if let rid = roomId, !rid.isEmpty {
                        print("[AuthService] 🔗 연결됨 roomId=\(rid)")
                        replaceRootinAuthService(.feed, coordinator: coordinator)
                    } else {
                        print("[AuthService] 🔓 미연결 상태 (roomId 없음)")
                    }
                }
                
                
            }
        }
    }
}
