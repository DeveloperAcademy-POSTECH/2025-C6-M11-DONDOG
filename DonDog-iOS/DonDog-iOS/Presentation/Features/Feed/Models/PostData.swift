//
//  PostData.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/16/25.
//

import FirebaseCore

struct PostData: Codable {
    let postId: String
    let uid: String
    let frontImageURL: String
    let backImageURL: String
    let caption: String
    let createdAt: Timestamp
    let stickerPostId: String
    let stickerType: String
    
    init(postId: String, uid: String, frontImageURL: String, backImageURL: String, caption: String = "", stickerPostId: String, stickerType: String = "null") {
        self.postId = postId
        self.uid = uid
        self.frontImageURL = frontImageURL
        self.backImageURL = backImageURL
        self.caption = caption
        self.createdAt = Timestamp()
        self.stickerPostId = stickerPostId
        self.stickerType = stickerType
    }
}
