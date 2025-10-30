//
//  PostData.swift
//  DonDog-iOS
//
//  Created by Ito on 10/27/25.
//

import FirebaseCore

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
    
    init(postId: String, uid: String, frontImageURL: String, backImageURL: String, caption: String, createdAt: Timestamp? = nil, stickerPostId: String, stickerType: String?) {
        self.postId = postId
        self.uid = uid
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
    var backURL: URL? { URL(string: backImageURL) }
}
