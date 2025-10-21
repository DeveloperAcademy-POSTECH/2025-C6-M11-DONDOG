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

    // 로그인 이후 또는 토큰 갱신 시 호출
    func uploadFCMToken(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("Users")
            .document(uid)
            .collection("fcmTokens")
            .document(token)
            .setData(["updatedAt": FieldValue.serverTimestamp()], merge: true)
    }
    
    // 현재 사용자 로그아웃 또는 회원 탈퇴 시 토큰 삭제
    func deleteFCMToken(completion: ((Error?) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?(nil)
            return
        }
        
        Messaging.messaging().token { token, error in
            if let error = error {
                print("FCM 토큰 가져오기 실패: \(error)")
                completion?(error)
                return
            }
            
            guard let token = token else {
                completion?(nil)
                return
            }
            
            Firestore.firestore()
                .collection("Users")
                .document(uid)
                .collection("fcmTokens")
                .document(token)
                .delete { error in
                    if let error = error {
                        print("Firestore 토큰 삭제 실패: \(error)")
                    } else {
                        print("Firestore에서 FCM 토큰 삭제 완료")
                    }
                    completion?(error)
                }
        }
    }
}
