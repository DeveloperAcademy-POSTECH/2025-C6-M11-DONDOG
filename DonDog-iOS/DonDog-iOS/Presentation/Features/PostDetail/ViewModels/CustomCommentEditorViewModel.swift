//
//  CustomCommentEditorViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class CustomCommentEditorViewModel: ObservableObject {
    @Published var comments: [CommentData] = []
    @Published var name: String = "익명"
    
    func saveComment(of text: String, for post: PostData) async {
        guard let roomId = try? await fetchCurrentUserRoomId(), !roomId.isEmpty else {
            print("roomId를 가져오지 못했습니다.")
            return
        }

        let commentRef = Firestore.firestore()
            .collection("Rooms")
            .document(roomId)
            .collection("comments")
            .document(post.postId)

        guard let currentUser = Auth.auth().currentUser else {
            print("현재 사용자 정보를 가져오지 못했습니다.")
            return
        }

        let tempComment = CommentData(
            authorId: currentUser.uid,
            text: text,
            createdAt: Timestamp(date: Date()),
            isDeleted: false,
            updatedAt: Timestamp(date: Date())
        )

        await MainActor.run {
            comments.append(tempComment)
        }

        Task {
            do {
                let commentData: [String: Any] = [
                    "uid": currentUser.uid,
                    "text": text,
                    "createdAt": Timestamp(date: Date())
                ]
                try await commentRef.collection("comments").addDocument(data: commentData)
            } catch {
                print("댓글 업로드 실패: \(error.localizedDescription)")
                
                await MainActor.run {
                    comments.removeAll { $0.authorId == tempComment.authorId }
                }
            }
        }
    }
    
    // TODO: User 싱글톤에서 roomId 가져오기
    private func fetchCurrentUserRoomId() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            print("사용자 정보가 잘못되었습니다.")
            return ""
        }
        
        let uid = currentUser.uid
        let document = try await Firestore.firestore().collection("Users").document(uid).getDocument()
        
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
}
