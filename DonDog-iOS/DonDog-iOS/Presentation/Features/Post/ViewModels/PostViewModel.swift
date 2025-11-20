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
    @Published var frontImageURL: URL?
    @Published var backImageURL: URL?
    
    private let connectUserInfo = UserPairingStore.shared
    
    init(post: PostData) {
        self.post = post
        checkIfItsMyPost()
        setupZoomedImages()
    }
    
    private func checkIfItsMyPost() {
        let isMine = post.authorId == connectUserInfo.myUid
        isMyPost = isMine
        postOwnerNickname = isMine ? "\(connectUserInfo.myName ?? "")" : "\(connectUserInfo.partnerName ?? "")"
    }
    
    private func setupZoomedImages() {
        frontImageURL = URL(string: post.frontImageURL)
        backImageURL = URL(string: post.backImageURL)
    }
    
    func deletePost() async {
        do {
            try await PostService.shared.deletePost(postId: post.postId)
        } catch {
            print("게시글 삭제에 실패했습니다: \(error)")
        }
    }
}
