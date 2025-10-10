//
//  InviteCodeService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/8/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class InviteCodeService {
    private let db = Firestore.firestore()
    
    // Invites/{inviteCode} 중복 체크 포함 유니크 코드 생성
    func generateUniqueInviteCode(completion: @escaping (Result<String, Error>) -> Void) {
        func attempt() {
            let allowedCharacters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
            let code = String((0..<6).map { _ in allowedCharacters.randomElement()! })
            
            db.collection("Invites").document(code).getDocument { document, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                // 중복 → 다시 시도
                if let document = document, document.exists {
                    attempt()
                } else {
                    completion(.success(code))
                }
            }
        }
        attempt()
    }

}
