//
//  ArchiveDetailViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class ArchiveDetailViewModel: ObservableObject {
    @Published var post: PostData
    @Published var isMyPost = false
    @Published var postOwnerNickname: String = ""
    @Published var frontImageURL: URL?
    @Published var backImageURL: URL?
    
    private let connectUserInfo = UserPairingStore.shared
    
    init(post: PostData) {
        self.post = post
        configure(with: post)
    }
    
    private func configure(with post: PostData) {
        let isMine = post.authorId == connectUserInfo.myUid
        isMyPost = isMine
        postOwnerNickname = isMine ? "\(connectUserInfo.myName ?? "")" : "\(connectUserInfo.partnerName ?? "")"
        frontImageURL = URL(string: post.frontImageURL)
        backImageURL = URL(string: post.backImageURL)
    }
    
    var currentPostId: String { post.postId }
    
    func deletePost() async {
        do {
            try await PostService.shared.deletePost(postId: currentPostId)
        } catch {
            print("게시글 삭제에 실패했습니다: \(error)")
        }
    }
}
