//
//  AuthService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/5/25.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

//:: 연결 여부 (User, roomID 있는지) 는 뷰모델에서 명시적으로 라우팅하는것으로 수정

@MainActor
final class ConnectState {
    static let shared = ConnectState()
    private init() {}
    
    var isConnected: Bool = false
    var roomId: String? = nil
}

final class AuthService {
    static var isAccountDeletionInProgress: Bool = false
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userDocListenr: ListenerRegistration?
    
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        if let listener = userDocListenr {
            listener.remove()
        }
    }
    
    func configureAuthBasedRouting(coordinator: AppCoordinator) {
        applyRouteForUser(coordinator: coordinator)
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            guard let self = self else { return }
            self.applyRouteForUser(coordinator: coordinator)
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
                ConnectState.shared.isConnected = false
                ConnectState.shared.roomId = nil
            }
            replaceRootinAuthService(.welcome, coordinator: coordinator)
            self.userDocListenr?.remove()
            self.userDocListenr = nil
            print("[AuthService] currentUser 없음 → auth 화면으로 이동")
            return
        }
        
        if AuthService.isAccountDeletionInProgress {
            Task { @MainActor in
                ConnectState.shared.isConnected = false
                ConnectState.shared.roomId = nil
            }
            replaceRootinAuthService(.welcome, coordinator: coordinator)
            return
        }
        
        user.getIDTokenResult(forcingRefresh: true) { _, _ in
            guard let refresehUser = Auth.auth().currentUser else {
                Task { @MainActor in
                    ConnectState.shared.isConnected = false
                    ConnectState.shared.roomId = nil
                }
                replaceRootinAuthService(.welcome, coordinator: coordinator)
                print("[AuthService] IDToken 분실로 current User 찾을 수 없음 → auth 화면으로 이동")
                return
            }
            
            let uid = refresehUser.uid
            let userDoc = Firestore.firestore().collection("Users").document(uid)
            
            self.userDocListenr?.remove()
            self.userDocListenr = userDoc.addSnapshotListener(includeMetadataChanges: true) { userDoc, error in
                if AuthService.isAccountDeletionInProgress {
                    Task { @MainActor in
                        ConnectState.shared.isConnected = false
                        ConnectState.shared.roomId = nil
                    }
                    replaceRootinAuthService(.welcome, coordinator: coordinator)
                    return
                }
                
                if let nsError = error as NSError? {
                    if nsError.domain == FirestoreErrorDomain,
                       nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
                        print("⚠️ permission-denied: 보안 규칙로 인해 읽기 불가 → auth로 이동")
                    } else {
                        print("⚠️ 사용자 문서 조회 오류: \(nsError.localizedDescription) → auth로 이동")
                    }
                    Task { @MainActor in
                        ConnectState.shared.isConnected = false
                        ConnectState.shared.roomId = nil
                    }
                    replaceRootinAuthService(.welcome, coordinator: coordinator)
                    return
                }
                
                guard let userDoc = userDoc else {
                    Task { @MainActor in
                        ConnectState.shared.isConnected = false
                        ConnectState.shared.roomId = nil
                    }
                    replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                    return
                }
                
                if userDoc.exists == false {
                    Task { @MainActor in
                        ConnectState.shared.isConnected = false
                        ConnectState.shared.roomId = nil
                    }
                    replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                    return
                }
                
                if userDoc.metadata.hasPendingWrites {
                    return
                }

                let data = userDoc.data() ?? [:]
                let roomId = data["roomId"] as? String
                Task { @MainActor in
                    ConnectState.shared.roomId = roomId
                    ConnectState.shared.isConnected = (roomId?.isEmpty == false)
                    if let rid = roomId, !rid.isEmpty {
                        print("[AuthService] 🔗 연결됨 roomId=\(rid)")
                    } else {
                        print("[AuthService] 🔓 미연결 상태 (roomId 없음)")
                    }
                }
            }
        }
    }
}
