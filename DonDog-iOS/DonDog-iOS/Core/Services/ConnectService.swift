//
//  ConnectService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/18/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ConnectService {
    static let shared = ConnectService() // 🔸 싱글톤 인스턴스
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// 연결 상태 (Observable하게 관리 가능)
    private(set) var isConnected: Bool = false
    
    /// Firestore에서 roomId 유무 확인
    func checkConnectionStatus(completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
                   print("[ConnectService] ❌ 로그인된 사용자가 없습니다")
                   self.isConnected = false
                   completion(false)
                   return
               }
               
        let userRef = db.collection("Users").document(uid)
        userRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("[ConnectService] 🔥 연결 상태 조회 실패: \(error.localizedDescription)")
                self?.isConnected = false
                completion(false)
                return
            }
            
            if let data = snapshot?.data(), let roomId = data["roomId"] as? String, !roomId.isEmpty {
                print("[ConnectService] ✅ 연결된 roomId 발견: \(roomId)")
                self?.isConnected = true
                completion(true)
            } else {
                print("[ConnectService] 🕊️ 연결되지 않은 상태")
                self?.isConnected = false
                completion(false)
            }
        }
    }
}
