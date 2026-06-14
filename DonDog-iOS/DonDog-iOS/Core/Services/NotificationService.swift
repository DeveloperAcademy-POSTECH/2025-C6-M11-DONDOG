//
//  NotificationService.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/13/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    private let fcmTokenKey = "fcmToken"
    private let fcmTokenUidKey = "fcmTokenUid"
    
    private func saveTokenToUserDefaults(_ token: String) {
        UserDefaults.standard.set(token, forKey: fcmTokenKey)
    }

    private func saveUidToUserDefaults(_ uid: String) {
        UserDefaults.standard.set(uid, forKey: fcmTokenUidKey)
    }
    
    func getTokenFromUserDefaults() -> String? {
        return UserDefaults.standard.string(forKey: fcmTokenKey)
    }

    private func getUidFromUserDefaults() -> String? {
        return UserDefaults.standard.string(forKey: fcmTokenUidKey)
    }
    
    // 현재 로그인 된 사용자 uid 기반으로 firestore에 저장
    func uploadFCMToken(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let cachedToken = getTokenFromUserDefaults()
        let cachedUid = getUidFromUserDefaults()

        // 같은 유저가 같은 토큰을 이미 업로드한 경우 중복 업로드를 건너뜀
        if cachedToken == token, cachedUid == uid {
            return
        }

        let ref = Firestore.firestore()
            .collection("Users").document(uid)
            .collection("fcmTokens").document(token)
        
        let env: String
#if DEBUG
    env = "dev"
#else
    env = "prod"
#endif
    let info: [String: Any] = [
        "env": env,
        "updatedAt": FieldValue.serverTimestamp()
    ]
        
        ref.setData(info, merge: true) { err in
            if let err = err {
                print("FCM 토큰 업로드 실패: \(err)")
            } else {
                print("FCM 토큰 업로드 성공: \(token.prefix(6))... [\(env)]")
                self.saveTokenToUserDefaults(token) // 로컬 캐싱
                self.saveUidToUserDefaults(uid)
            }
        }
    }
    
    // 현재 사용자 로그아웃 또는 회원 탈퇴 시 토큰 삭제
    func deleteFCMToken() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let token = try await Messaging.messaging().token()
        
        try await Firestore.firestore()
            .collection("Users")
            .document(uid)
            .collection("fcmTokens")
            .document(token)
            .delete()
        
        UserDefaults.standard.removeObject(forKey: self.fcmTokenKey)
        UserDefaults.standard.removeObject(forKey: self.fcmTokenUidKey)
        print("Firestore에서 FCM 토큰 삭제 완료")
    }
}
