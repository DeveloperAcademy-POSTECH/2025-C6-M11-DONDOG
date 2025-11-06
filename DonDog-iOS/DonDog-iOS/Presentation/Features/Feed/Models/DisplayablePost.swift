//
//  PostData.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/16/25.
//

import FirebaseCore
import UIKit

// MARK: - DisplayablePost
struct DisplayablePost: Identifiable {
    let id: String
    let post: PostData
    var frontImageURL: URL?
    var backImageURL: URL?
    var name: String
    let isMyPost: Bool
    
    init(post: PostData, frontImage: URL? = nil, backImage: URL? = nil, name: String = "익명", isMyPost: Bool = false) {
        self.id = post.postId
        self.post = post
        self.frontImageURL = frontImage
        self.backImageURL = backImage
        self.name = name
        self.isMyPost = isMyPost
    }
    
    var caption: String { post.caption }
    var createdAt: Date { post.createdAt.dateValue() }
    var uid: String { post.authorId }
    var postId: String { post.postId }
    var stickerPostId: String { post.stickerPostId ?? "" }
    var stickerType: String? { post.stickerType }
    
    var isReady: Bool {
        frontImageURL != nil && backImageURL != nil
    }
}
