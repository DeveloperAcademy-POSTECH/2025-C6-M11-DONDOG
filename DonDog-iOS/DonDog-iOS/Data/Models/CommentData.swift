//
//  CommentData.swift
//  DonDog-iOS
//
//  Created by Ito on 10/27/25.
//

import FirebaseCore

struct CommentData: Codable {
    let commentId: String
    let authorId: String
    let text: String
    let createdAt: Timestamp
    let isDeleted: Bool
    let updatedAt: Timestamp?
    
    init(commentId: String, authorId: String, text: String, createdAt: Timestamp, isDeleted: Bool = false, updatedAt: Timestamp) {
        self.commentId = commentId
        self.authorId = authorId
        self.text = text
        self.createdAt = createdAt
        self.isDeleted = isDeleted
        self.updatedAt = updatedAt
    }
}
