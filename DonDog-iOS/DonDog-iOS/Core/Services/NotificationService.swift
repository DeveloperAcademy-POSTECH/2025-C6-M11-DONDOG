//
//  NotificationService.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/13/25.
//

import FirebaseAuth
import FirebaseFirestore

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
}
