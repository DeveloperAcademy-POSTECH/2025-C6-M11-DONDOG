//
//  PostService.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/20/25.
//

import FirebaseFirestore
import FirebaseStorage
import Foundation

// 분리 예정
enum PostServiceError: Error {
    case unauthorized
    case postNotFound
    case invalidIdentifier
}

final class PostService {
    static let shared = PostService()
    private init() {}
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    let connectUserInfo = UserPairingStore.shared
    
    func deletePost(postId: String) async throws {
        guard !postId.isEmpty else {
            print("postId가 비어있습니다.")
            return
        }
        
        let postRef = db.collection("Rooms").document(connectUserInfo.roomId ?? "").collection("posts").document(postId)
        
        let postDocument = try await postRef.getDocument()
        
        guard let postData = postDocument.data(), postDocument.exists else {
            print("post를 불러오지 못했습니다.")
            return
        }
        
        guard let authorUid = postData["authorId"] as? String else {
            print("authorId를 불러오지 못했습니다.")
            return
        }
        
        guard authorUid == connectUserInfo.myUid else {
            print("권한이 없습니다. (작성자가 아닙니다)")
            return
        }
        
        // 1. 스토리지에서 이미지 삭제
        if let frontURLString = postData["frontImageURL"] as? String {
            try? await storage.reference(forURL: frontURLString).delete()
        }
        if let backURLString = postData["backImageURL"] as? String {
            try? await storage.reference(forURL: backURLString).delete()
        }
        
        // 4. 포스트 삭제
        try await postRef.delete()
    }
}
