//
//  PostService.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/20/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

// 분리 예정
enum PostServiceError: Error {
    case unauthorized
    case postNotFound
}

final class PostService {
    static let shared = PostService()
    private init() {}
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func deletePost(postId: String, in roomId: String, by userId: String) async throws {
        let postRef = db.collection("Rooms").document(roomId).collection("posts").document(postId)
        
        let postDocument = try await postRef.getDocument()
        
        guard let postData = postDocument.data(), postDocument.exists else {
            throw PostServiceError.postNotFound
        }
        
        guard let authorUid = postData["uid"] as? String, authorUid == userId else {
            throw PostServiceError.unauthorized
        }
        
        let commentDocRef = db.collection("Rooms").document(roomId).collection("comments").document(postId)
        
        // 1. 스토리지에서 이미지 삭제
        if let frontURLString = postData["frontImageURL"] as? String {
            try? await storage.reference(forURL: frontURLString).delete()
        }
        if let backURLString = postData["backImageURL"] as? String {
            try? await storage.reference(forURL: backURLString).delete()
        }
        
        // 2. 코멘트 삭제
        let commentsSnapshot = try await commentDocRef.collection("comments").getDocuments()
        if !commentsSnapshot.documents.isEmpty {
            let batch = db.batch()
            commentsSnapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
        }
        
        // 3. 코멘트 문서 삭제
        if (try? await commentDocRef.getDocument())?.exists == true {
            try await commentDocRef.delete()
        }
        
        // 4. 포스트 삭제
        try await postRef.delete()
    }
    
    func deleteComment(_ comment: Comment, postId: String, in roomId: String) async throws {
        let commentRef = db.collection("Rooms")
            .document(roomId)
            .collection("comments")
            .document(postId)
            .collection("comments")
            .document(comment.id)
            
        try await commentRef.delete()
    }
}
