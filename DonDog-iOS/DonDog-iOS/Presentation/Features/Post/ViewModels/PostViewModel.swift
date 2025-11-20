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
    @Published var post: PostData
    @Published var isMyPost = false
    @Published var postOwnerNickname: String = ""
    
    private let connectUserInfo = UserPairingStore.shared
    
    init(post: PostData) {
        self.post = post
        checkIfItsMyPost()
    }
    
    private func checkIfItsMyPost() {
        let isMine = post.authorId == connectUserInfo.myUid
        isMyPost = isMine
        postOwnerNickname = isMine ? "\(connectUserInfo.myName ?? "")" : "\(connectUserInfo.partnerName ?? "")"
    }
    
    func deletePost() async {
        do {
            try await PostService.shared.deletePost(postId: post.postId)
        } catch {
            print("게시글 삭제에 실패했습니다: \(error)")
        }
    }
}
