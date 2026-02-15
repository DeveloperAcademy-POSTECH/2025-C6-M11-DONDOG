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
    
    private var cachedPosts: [PostData] = []
    private var cachedLastPostCreatedAt: Timestamp?
    
    var allPosts: [PostData] { cachedPosts }
    var lastPostCreatedAt: Timestamp? { cachedLastPostCreatedAt }
    
    func update(with posts: [PostData]) {
        cachedPosts = posts.sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() }
        cachedLastPostCreatedAt = cachedPosts.last?.createdAt
    }
    
    func merge(newPosts: [PostData]) {
        guard newPosts.isEmpty == false else { return }
        var dict: [String: PostData] = [:]
        for post in cachedPosts { dict[post.postId] = post }
        for post in newPosts { dict[post.postId] = post }
        
        let merged = dict.values.sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() }
        cachedPosts = merged
        cachedLastPostCreatedAt = merged.last?.createdAt
    }
    
    func clear() {
        cachedPosts = []
        cachedLastPostCreatedAt = nil
    }
}
