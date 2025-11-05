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
    
    private let connectUserInfo = UserPairingStore.shared
    
    init(posts: [PostData]) {
        self.posts = posts
    }
    
    func checkIfItsMyPost(of index: Int) {
        showUnauthorizedAlert = posts[index].authorId != connectUserInfo.myUid
    }
    
    func handleDeleteRequest(for post: PostData) {
        if post.authorId == connectUserInfo.myUid {
            showDeleteConfirmAlert = true
        } else {
            showUnauthorizedAlert = true
        }
    }
    
    func deletePost(for post: PostData) async {
        do {
            try await PostService.shared.deletePost(postId: post.postId)
            
            await MainActor.run {
                posts.removeAll { $0.postId == post.postId }
            }
        } catch {
            print("게시글 삭제에 실패했습니다: \(error)")
        }
    }
}
