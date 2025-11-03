//
//  PostViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class PostViewModel: ObservableObject {
    @Published var showDeleteConfirmAlert = false
    @Published var showUnauthorizedAlert = false
    @Published var posts: [PostData]
    
    private var currentUserId: String?
    
    init(posts: [PostData]) {
        self.posts = posts
        
    }
    
    func checkIfItsMyPost(of index: Int) {
        // TODO: currentUser 정보 User Singleton에서 가져오기
        guard let currentUser = Auth.auth().currentUser else {
            print("사용자 정보에 문제가 있습니다.")
            return
        }
        showUnauthorizedAlert = posts[index].authorId != currentUser.uid
    }
    
    func handleDeleteRequest(for post: PostData) {
        // TODO: currentUser 정보 User Singleton에서 가져오기
        currentUserId = Auth.auth().currentUser!.uid
        
        if post.authorId == currentUserId {
            showDeleteConfirmAlert = true
        } else {
            showUnauthorizedAlert = true
        }
    }
    
    func deletePost(for post: PostData) async {
        do {
            guard let roomId = try? await fetchCurrentUserRoomId(), !roomId.isEmpty else {
                print("roomId를 가져오지 못했습니다.")
                return
            }
            
            guard let userId = currentUserId, !userId.isEmpty else {
                print("현재 사용자 id를 가져오지 못했습니다.")
                return
            }
            
            try await PostService.shared.deletePost(postId: post.postId, in: roomId, by: userId)
            
            await MainActor.run {
                posts.removeAll { $0.postId == post.postId }
            }
        } catch {
            print("게시글 삭제에 실패했습니다: \(error)")
        }
    }
    
    private func updateDB() {
        // TODO: 새로고침(데이터 업데이트 적용)
    }
    
    // TODO: User 싱글톤에서 roomId 가져오기
    private func fetchCurrentUserRoomId() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            print("사용자 정보가 잘못되었습니다.")
            return ""
        }
        
        currentUserId = currentUser.uid
        let document = try await Firestore.firestore().collection("Users").document(currentUserId ?? "").getDocument()
        
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
