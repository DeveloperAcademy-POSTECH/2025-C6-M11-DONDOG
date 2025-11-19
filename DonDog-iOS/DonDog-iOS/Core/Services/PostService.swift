//
//  PostService.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/20/25.
//

import FirebaseFirestore
import FirebaseStorage
import Foundation

final class PostService {
    static let shared = PostService()
    private init() {}
    
    private let storage = Storage.storage()
    private let connectUserInfo = UserPairingStore.shared
    private let dataManager: DataManagerProtocol = DataManager.shared
    
    func deletePost(postId: String) async throws {
        let roomId = connectUserInfo.roomId ?? ""
        let basePath = "Rooms/\(roomId)/posts/\(postId)"

        let post: PostData = try await dataManager.fetch(path: "\(basePath)")

        try await dataManager.deleteStorageFile(urlString: post.frontImageURL)
        try await dataManager.deleteStorageFile(urlString: post.backImageURL)

        let stickers: [AttachedSticker] = try await dataManager.fetchCollection(
            path: "\(basePath)/stickerAttachments"
        )

        let stickerPaths = stickers.map { "\(basePath)/stickerAttachments/\($0.id)" }

        if !stickerPaths.isEmpty {
            try await dataManager.batchDelete(paths: stickerPaths)
        }

        try await dataManager.delete(path: "\(basePath)")
    }
}
