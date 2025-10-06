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
    
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
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
            return
        }
        
        user.getIDTokenResult(forcingRefresh: true) { _, _ in
            guard let refresehUser = Auth.auth().currentUser else {
                replaceRootinAuthService(.auth, coordinator: coordinator)
                return
            }
            
            let uid = refresehUser.uid
            let userDoc = Firestore.firestore().collection("Users").document(uid)
            
            userDoc.getDocument(source: .server) { userDoc, error in
                if let nsError = error as NSError? {
                    if nsError.domain == FirestoreErrorDomain,
                       nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
                        print("⚠️ permission-denied: 보안 규칙로 인해 읽기 불가 → profileSetup로 이동")
                    } else {
                        print("⚠️ 사용자 문서 조회 오류: \(nsError.localizedDescription) → profileSetup로 이동")
                    }
                    replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                    return
                }
                
                guard let userDoc = userDoc else {
                    replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                    return
                }
                
                if userDoc.exists {
                    let roomId = (userDoc.get("roomId") as? String) ?? ""
                    if roomId.isEmpty {
                        replaceRootinAuthService(.invite, coordinator: coordinator)
                    } else {
                        replaceRootinAuthService(.feed, coordinator: coordinator)
                    }
                } else {
                    replaceRootinAuthService(.profileSetup, coordinator: coordinator)
                }
            }
        }
    }
}
