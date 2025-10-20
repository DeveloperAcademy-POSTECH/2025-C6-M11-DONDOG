//
//  ArchiveDetailViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/16/25.
//

import Combine
import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
final class ArchiveDetailViewModel: ObservableObject {
    @Published var posts: [ArchivePost] = []
    @Published var userNameByUid: [String: String] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let roomId: String
    let date: Date
    
    private let db = Firestore.firestore()
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return cal
    }()
    
    init(roomId: String, date: Date, initialPosts: [ArchivePost]? = nil) {
        self.roomId = roomId
        self.date = date
        if let initialPosts { self.posts = initialPosts }
        Task {
            if initialPosts != nil {
                await loadPostDetails()   // 댓글 + 이름만 추가로 가져옴
            } else {
                await fetchDailyPosts()
            }
        }
    }
    
    func loadPostDetails() async {
        isLoading = true
        defer { isLoading = false }
        
        var updated: [ArchivePost] = []
        var uidSet = Set<String>()
        
        for p in posts {
            let comments = await fetchComments(for: p.id)
            comments.forEach { uidSet.insert($0.uid) }
            if let au = p.authorUid { uidSet.insert(au) }    // authorUid가 모델에 있다면
            
            let loadData = ArchivePost(
                id: p.id,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
                authorUid: p.authorUid,
                authorName: p.authorName,
                frontImageURL: p.frontImageURL,
                backImageURL: p.backImageURL,
                caption: p.caption,
                stickerPostId: p.stickerPostId,
                stickerType: p.stickerType,
                comments: comments
            )
            updated.append(loadData)
        }
        
        self.posts = updated
        self.userNameByUid = await fetchUserNamesIndividually(uids: Array(uidSet))
    }
    
    // initialPosts가 없을 때만 실행
    func fetchDailyPosts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
            
            let snapshot = try await db.collection("Rooms")
                .document(roomId)
                .collection("posts")
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("createdAt", isLessThan: Timestamp(date: endOfDay))
                .order(by: "createdAt", descending: false)
                .getDocuments()
            
            var fetched: [ArchivePost] = []
            var uidSet = Set<String>()
            
            for doc in snapshot.documents {
                let data = doc.data()
                let tsCreated = data["createdAt"] as? Timestamp
                let tsUpdated = data["updatedAt"] as? Timestamp
                
                let caption = data["caption"] as? String
                let stickerPostId = data["stickerPostId"] as? String
                let stickerTypeString = (data["stickerType"] as? String)?.lowercased()
                let stickerType = stickerTypeString.flatMap { StickerType(rawValue: $0) }
                
                let authorUid = data["uid"] as? String
                if let authorUid { uidSet.insert(authorUid) }
                
                let comments = await fetchComments(for: doc.documentID)
                comments.forEach { uidSet.insert($0.uid) }
                
                fetched.append(
                    ArchivePost(
                        id: doc.documentID,
                        createdAt: tsCreated?.dateValue() ?? .distantPast,
                        updatedAt: tsUpdated?.dateValue() ?? tsCreated?.dateValue() ?? .distantPast,
                        authorUid: authorUid,
                        authorName: data["authorName"] as? String,
                        frontImageURL: (data["frontImageURL"] as? String).flatMap(URL.init(string:)),
                        backImageURL: (data["backImageURL"]  as? String).flatMap(URL.init(string:)),
                        caption: caption,
                        stickerPostId: stickerPostId,
                        stickerType: stickerType,
                        comments: comments
                    )
                )
            }
            
            self.posts = fetched
            self.userNameByUid = await fetchUserNamesIndividually(uids: Array(uidSet))
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func fetchUserNamesIndividually(uids: [String]) async -> [String: String] {
        let unique = Array(Set(uids))
        guard !unique.isEmpty else { return [:] }
        
        return await withTaskGroup(of: (String, String?).self, returning: [String: String].self) { group in
            for uid in unique {
                group.addTask { [db] in
                    do {
                        let snap = try await db.collection("Users").document(uid).getDocument()
                        let name = snap.data()?["name"] as? String
                        return (uid, name)
                    } catch {
                        return (uid, nil)
                    }
                }
            }
            
            var result: [String: String] = [:]
            for await (uid, name) in group {
                result[uid] = (name?.isEmpty == false) ? name! : "익명"
            }
            return result
        }
    }
    
    func fetchComments(for postId: String) async -> [Comment] {
        do {
            let snap = try await db.collection("Rooms")
                .document(roomId)
                .collection("comments")
                .document(postId)
                .collection("comments")
                .order(by: "createdAt", descending: false)
                .getDocuments()
            
            return snap.documents.compactMap { Comment(doc: $0) }
        } catch {
            print("댓글 로드 실패:", error.localizedDescription)
            return []
        }
    }
    
    func deleteComment(_ comment: Comment, from post: ArchivePost) async {
        let commentRef = db.collection("Rooms")
            .document(roomId)
            .collection("comments")
            .document(post.id)
            .collection("comments")
            .document(comment.id)
            
        do {
            try await commentRef.delete()
            
            if let postIndex = posts.firstIndex(where: { $0.id == post.id }) {
                posts[postIndex].comments.removeAll { $0.id == comment.id }
            }
            
        } catch {
            self.errorMessage = "댓글 삭제에 실패했습니다."
        }
    }
}
