//
//  PostData.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/16/25.
//

import FirebaseCore
import UIKit

struct PostData: Codable, Hashable {
    let postId: String
    let authorId: String
    let frontImageURL: String
    let backImageURL: String
    let caption: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    let stickerPostId: String
    let stickerType: String?
    
    init(postId: String, authorId: String, frontImageURL: String, backImageURL: String, caption: String = "", createdAt: Timestamp? = nil, stickerPostId: String, stickerType: String?) {
        self.postId = postId
        self.authorId = authorId
        self.frontImageURL = frontImageURL
        self.backImageURL = backImageURL
        self.caption = caption
        self.createdAt = createdAt ?? Timestamp()
        self.updatedAt = Timestamp()
        self.stickerPostId = stickerPostId
        self.stickerType = stickerType
    }
}

extension PostData {
    var frontURL: URL? { URL(string: frontImageURL) }
    var backURL: URL?  { URL(string: backImageURL) }
}

// MARK: - DisplayablePost
/// UI에서 표시하기 위한 게시물 모델 (Firestore 데이터 + 다운로드된 이미지 + 닉네임)
struct DisplayablePost: Identifiable {
    let id: String  // postId
    let post: PostData
    var frontImageURL: URL? = nil
    var backImageURL: URL? = nil
    var stickerImage: UIImage?  // 이 게시물에 붙은 스티커 이미지
    var nickname: String
    let isMyPost: Bool  // 내 게시물인지 여부
    
    init(post: PostData, frontImage: URL? = nil, backImage: URL? = nil, stickerImage: UIImage? = nil, nickname: String = "익명", isMyPost: Bool = false) {
        self.id = post.postId
        self.post = post
        self.frontImageURL = frontImage
        self.backImageURL = backImage
        self.stickerImage = stickerImage
        self.nickname = nickname
        self.isMyPost = isMyPost
    }
    
    // 편의 속성 - post 데이터에 쉽게 접근
    var caption: String { post.caption }
    var createdAt: Date { post.createdAt.dateValue() }
    var uid: String { post.authorId }
    var postId: String { post.postId }
    var stickerPostId: String { post.stickerPostId }
    var stickerType: String? { post.stickerType }
    
    // 이미지가 모두 다운로드되었는지 확인
    var isReady: Bool {
        frontImageURL != nil && backImageURL != nil
    }
}
