//
//  AuthService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/5/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
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
            }
        }
        
        guard let user = Auth.auth().currentUser else {
            replaceRootinAuthService(.auth, coordinator: coordinator)
            self.userDocListenr?.remove()
            self.userDocListenr = nil
            return
        }
        
        user.getIDTokenResult(forcingRefresh: true) { _, _ in
            guard let refresehUser = Auth.auth().currentUser else {
                replaceRootinAuthService(.auth, coordinator: coordinator)
                return
            }
            
            let uid = refresehUser.uid
            let userDoc = Firestore.firestore().collection("Users").document(uid)
            
            self.userDocListenr?.remove()
            self.userDocListenr = userDoc.addSnapshotListener(includeMetadataChanges: true) { userDoc, error in
                if let nsError = error as NSError? {
                    if nsError.domain == FirestoreErrorDomain,
                       nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
                        print("⚠️ permission-denied: 보안 규칙로 인해 읽기 불가 → auth로 이동")
                    } else {
                        print("⚠️ 사용자 문서 조회 오류: \(nsError.localizedDescription) → auth로 이동")
                    }
                    replaceRootinAuthService(.auth, coordinator: coordinator)
                    return
                }
                
                guard let userDoc = userDoc else {
                    replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                    return
                }
                
                if userDoc.metadata.hasPendingWrites {
                    return
                }
            }
        }
    }
}
