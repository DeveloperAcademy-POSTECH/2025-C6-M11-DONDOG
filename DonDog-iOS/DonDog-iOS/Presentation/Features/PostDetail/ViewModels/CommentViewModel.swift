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
            let roomId = try await getCurrentUserRoomId()
            self.roomId = roomId
            
            let snapshot = try await db
                .collection("Rooms")
                .document(roomId)
                .collection("Comments")
                .document(postId)
                .collection("comments")
                .getDocuments()
            
            let fetched = snapshot.documents.compactMap { Comment(doc: $0) }
            await MainActor.run {
                self.comments = fetched.sorted { $0.createdAt < $1.createdAt } as! [CommentData]
            }
        } catch {
            print("댓글 불러오기에 실패했습니다: \(error.localizedDescription)")
        }
    }
    
    private func getCurrentUserRoomId() async throws -> String {
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
    
    private func getCurrentUserRoomId(completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("사용자 정보에 문제가 있습니다.")
            return
        }
        
        let uid = currentUser.uid
        
        db.collection("Users").document(uid).getDocument { document, error in
            if error != nil {
                print("사용자 문서를 가져오지 못했습니다.")
                return
            }
            
            guard let document = document,
                  let roomId = document.get("roomId") as? String,
                  !roomId.isEmpty else {
                print("roomId를 가져오지 못했습니다.")
                return
            }
            
            completion(.success(roomId))
        }
    }
}
