//
//  PostData.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/16/25.
//

import FirebaseCore
import UIKit

struct PostData: Codable {
    let postId: String
    let uid: String
    let frontImageURL: String
    let backImageURL: String
    let caption: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    let stickerPostId: String
    let stickerType: String?
    
    init(postId: String, uid: String, frontImageURL: String, backImageURL: String, caption: String = "", stickerPostId: String, stickerType: String?) {
        self.postId = postId
        self.uid = uid
        self.frontImageURL = frontImageURL
        self.backImageURL = backImageURL
        self.caption = caption
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
        self.stickerPostId = stickerPostId
        self.stickerType = stickerType
        
    }
}

// MARK: - DisplayablePost
/// UI에서 표시하기 위한 게시물 모델 (Firestore 데이터 + 다운로드된 이미지 + 닉네임)
struct DisplayablePost: Identifiable {
    let id: String  // postId
    let post: PostData
    var frontImage: UIImage?
    var backImage: UIImage?
    var nickname: String
    let isMyPost: Bool  // 내 게시물인지 여부
    
    init(post: PostData, frontImage: UIImage? = nil, backImage: UIImage? = nil, nickname: String = "익명", isMyPost: Bool = false) {
        self.id = post.postId
        self.post = post
        self.frontImage = frontImage
        self.backImage = backImage
        self.nickname = nickname
        self.isMyPost = isMyPost
    }
    
    // 편의 속성 - post 데이터에 쉽게 접근
    var caption: String { post.caption }
    var createdAt: Date { post.createdAt.dateValue() }
    var uid: String { post.uid }
    var postId: String { post.postId }
    var stickerPostId: String { post.stickerPostId }
    var stickerType: String? { post.stickerType }
    
    // 이미지가 모두 다운로드되었는지 확인
    var isReady: Bool {
        frontImage != nil && backImage != nil
    }
}
