//
//  PostService.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/20/25.
//

import FirebaseFirestore
import FirebaseStorage
import Foundation

// 분리 예정
enum PostServiceError: Error {
    case unauthorized
    case postNotFound
    case invalidIdentifier
}

final class PostService {
    static let shared = PostService()
    private init() {}
    
    private let storage = Storage.storage()
    private let connectUserInfo = UserPairingStore.shared
    private let dataManager: DataManagerProtocol = DataManager.shared
    
    func deletePost(postId: String) async throws {
        let post: PostData = try await dataManager.fetch(path: "Rooms/\(connectUserInfo.roomId ?? "")/posts/\(postId)")
        
        try await dataManager.deleteStorageFile(urlString: post.frontImageURL)
        
        try await dataManager.deleteStorageFile(urlString: post.backImageURL)
        
        try await dataManager.delete(path: "Rooms/\(connectUserInfo.roomId ?? "")/posts/\(postId)")
    }
}
