//
//  ArchivePost.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/17/25.
//

import Foundation

struct ArchivePost: Identifiable, Hashable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let authorName: String?
    
    let frontImageURL: URL?
    let backImageURL: URL?
    
    let caption: String?
    let stickerPostId: String?
    let stickerType: StickerType?
    
    var thumbnailURL: URL? { frontImageURL ?? backImageURL }
    var hasSticker: Bool { stickerPostId != nil && stickerPostId != nil }
}
