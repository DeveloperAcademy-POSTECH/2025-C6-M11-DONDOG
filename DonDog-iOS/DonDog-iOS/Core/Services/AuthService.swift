//
//  AuthService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/5/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

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
                
                NSLog("[AuthService replaceRootinAuthService함수] 🔄 \(coordinator.root) → \(route)")
            }
        }
        
        guard let user = Auth.auth().currentUser else {
            Task { @MainActor in
                UserPairingStore.shared.reset()
            }
            replaceRootinAuthService(.welcome, coordinator: coordinator)
            self.userDocListenr?.remove()
            self.userDocListenr = nil
            NSLog("[AuthService] currentUser 없음 → welcome 화면으로 이동")
            return
        }
        
        if AuthService.isAccountDeletionInProgress {
            return
        }
        
        user.getIDTokenResult(forcingRefresh: true) { _, _ in
            /// 로그인 안됨 -> welcome으로 이동
            guard let refreshUser = Auth.auth().currentUser else {
                Task { @MainActor in
                    UserPairingStore.shared.reset()
                }
                replaceRootinAuthService(.welcome, coordinator: coordinator)
                NSLog("[AuthService] IDToken 분실로 current User 찾을 수 없음 → welcome 화면으로 이동")
                return
            }

            Task { @MainActor in
                let state = UserPairingStore.shared
                state.myUid = refreshUser.uid
                state.myName = nil
                state.roomId = nil
                state.partnerUid = nil
                state.partnerName = nil
                state.isConnected = false
                NSLog("[AuthService] 🚀 Primed UserPairingStore with myUid early: uid=\(state.myUid ?? "nil")")
            }
            
            // 현재 기기의 FCM 토큰 firestore에 업로드
            Messaging.messaging().token { token, error in
                if let token = token {
                    NotificationService.shared.uploadFCMToken(token)
                    
                    // 로그인 및 토큰 업로드 성공 후 토픽 구독
                    Messaging.messaging().subscribe(toTopic: "daily_random_notification") { error in
                        if let error = error {
                            NSLog("토픽 구독 실패: \(error.localizedDescription)")
                        } else {
                            NSLog("토픽 구독 성공")
                        }
                    }
                } else if let error = error {
                    NSLog("FCM 토큰 획득 실패 (AuthService): \(error.localizedDescription)")
                }
            }
            
            let uid = refreshUser.uid
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
                        NSLog("⚠️ 사용자 문서 조회 오류: \(nsError.localizedDescription) → welcome로 이동")
                        Task { @MainActor in
                            UserPairingStore.shared.reset()
                        }
                        replaceRootinAuthService(.welcome, coordinator: coordinator)
                    } else {
                        // 오류는 없지만 스냅샷이 nil인 경우: profileSetup으로 이동
                        Task { @MainActor in
                            UserPairingStore.shared.reset()
                        }
                        replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                    }
                    return
                }
                
                /// user 문서가 없을때 (가입 후 프로필 미완성) -> profileSetup
                if userDoc.exists == false {
                    Task { @MainActor in
                        UserPairingStore.shared.reset()
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
                    let state = UserPairingStore.shared
                    if state.myUid == nil { state.myUid = refreshUser.uid }
                    state.myName = data["name"] as? String
                    
                    guard let rid = roomId, !rid.isEmpty else {
                        state.reset()
                        NSLog("[AuthService] 🔓 미연결 상태 (roomId 없음)")
                        replaceRootinAuthService(.feed, coordinator: coordinator)
                        return
                    }
                    
                    do {
                        let db = Firestore.firestore()
                        let roomDoc = try await db.collection("Rooms").document(rid).getDocument()
                        
                        guard let roomData = roomDoc.data(), let participants = roomData["participants"] as? [String] else {
                            state.reset()
                            replaceRootinAuthService(.welcome, coordinator: coordinator)
                            return
                        }
                        
                        if let partnerUid = participants.first(where: { $0 != refreshUser.uid }) {
                            let partnerDoc = try await db.collection("Users").document(partnerUid).getDocument()
                            state.partnerUid = partnerUid
                            state.partnerName = partnerDoc.data()?["name"] as? String
                            NSLog("[AuthService] Partner Info: uid = \(partnerUid), name = \(state.partnerName ?? "nil")")
                        } else {
                            state.partnerUid = nil
                            state.partnerName = nil
                        }
                        
                        state.roomId = rid
                        state.isConnected = true
                        
                        NSLog("[AuthService] My Info: uid = \(state.myUid ?? "nil"), name = \(state.myName ?? "nil")")
                        NSLog("[AuthService] 상태: 연결 상태 =\(state.isConnected), roomId=\(state.roomId ?? "nil")")
                        replaceRootinAuthService(.feed, coordinator: coordinator)
                        
                    } catch {
                        NSLog("AuthService에서 정보 로딩 중 에러: \(error.localizedDescription)")
                        state.reset()
                        replaceRootinAuthService(.welcome, coordinator: coordinator)
                    }
                }
            }
        }
    }
}
