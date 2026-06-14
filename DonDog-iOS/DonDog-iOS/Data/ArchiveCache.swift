//
//  ArchiveCache.swift
//  DonDog-iOS
//
//  Created by Codex on 2/10/26.
//

import FirebaseCore

actor ArchiveCache {
    static let shared = ArchiveCache()
    private init() {}
    
    private var cachedRoomId: String?
    private var cachedPosts: [PostData] = []
    private var cachedLastPostCreatedAt: Timestamp?
    
    func snapshot(for roomId: String) -> (posts: [PostData], lastPostCreatedAt: Timestamp?) {
        guard cachedRoomId == roomId else { return ([], nil) }
        return (cachedPosts, cachedLastPostCreatedAt)
    }
    
    func update(roomId: String, with posts: [PostData]) {
        cachedRoomId = roomId
        cachedPosts = posts.sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() }
        cachedLastPostCreatedAt = cachedPosts.last?.createdAt
    }
    
    func merge(roomId: String, newPosts: [PostData]) {
        guard cachedRoomId == roomId else {
            update(roomId: roomId, with: newPosts)
            return
        }
        guard newPosts.isEmpty == false else { return }
        var dict: [String: PostData] = [:]
        for post in cachedPosts { dict[post.postId] = post }
        for post in newPosts { dict[post.postId] = post }
        
        let merged = dict.values.sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() }
        cachedPosts = merged
        cachedLastPostCreatedAt = merged.last?.createdAt
    }
    
    func clear() {
        cachedRoomId = nil
        cachedPosts = []
        cachedLastPostCreatedAt = nil
    }
}
