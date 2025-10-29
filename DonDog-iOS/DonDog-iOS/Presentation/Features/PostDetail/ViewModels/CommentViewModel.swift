//
//  CommentViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class CommentViewModel: ObservableObject {
    @Published var comments: [CommentData] = []
    
    private let db = Firestore.firestore()
    private var roomId: String?
    
    func fetchComments(postId: String) async {
        do {
            let roomId = try await fetchCurrentUserRoomId()
            self.roomId = roomId
            
            let snapshot = try await db
                .collection("Rooms")
                .document(roomId)
                .collection("comments")
                .document(postId)
                .collection("comments")
                .getDocuments()
            
            let fetched: [CommentData] = snapshot.documents.compactMap { doc in
                let data = doc.data()
                
                guard
                    let commentId = data["commentId"] as? String ?? doc.documentID as String?,
                    let authorId = data["authorId"] as? String ?? data["uid"] as? String,
                    let text = data["text"] as? String,
                    let createdAt = data["createdAt"] as? Timestamp
                else {
                    return nil
                }
                
                let isDeleted = data["isDeleted"] as? Bool ?? false
                let updatedAt = (data["updatedAt"] as? Timestamp) ?? createdAt
                
                return CommentData(
                    commentId: commentId,
                    authorId: authorId,
                    text: text,
                    createdAt: createdAt,
                    isDeleted: isDeleted,
                    updatedAt: updatedAt
                )
            }
            
            await MainActor.run {
                self.comments = fetched.sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() }
            }
        } catch {
            print("댓글 불러오기에 실패했습니다: \(error.localizedDescription)")
        }
    }
    
    // TODO: User 싱글톤에서 roomId 가져오기
    private func fetchCurrentUserRoomId() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            print("사용자 정보가 잘못되었습니다.")
            return ""
        }
        
        let uid = currentUser.uid
        let document = try await db.collection("Users").document(uid).getDocument()
        
        guard document.exists else {
            print("사용자 문서를 가져오지 못했습니다.")
            return ""
        }
        
        let roomId = document.get("roomId") as? String ?? ""
        guard !roomId.isEmpty else {
            print("roomId를 가져오지 못했습니다.")
            return ""
        }
        
        return roomId
    }
    
    
    // TODO: DB Manager로 교체
    func deleteComment(for comment: CommentData, in postId: String) async throws {
        let roomId = try await fetchCurrentUserRoomId()
        
        guard !comment.commentId.isEmpty, !postId.isEmpty, !roomId.isEmpty else {
            throw PostServiceError.invalidIdentifier
        }
        
        let commentRef = Firestore.firestore().collection("Rooms")
            .document(roomId)
            .collection("comments")
            .document(postId)
            .collection("comments")
            .document(comment.commentId)
        
        try await commentRef.delete()
    }
}
