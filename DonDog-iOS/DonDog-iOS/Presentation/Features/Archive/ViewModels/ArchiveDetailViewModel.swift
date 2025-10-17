//
//  ArchiveDetailViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/16/25.
//

import SwiftUI

import Combine
import FirebaseFirestore
import FirebaseAuth
import Foundation

enum StickerType: String, Codable, CaseIterable, Hashable {
    case love, cool, what, upset, sad
}

@MainActor
final class ArchiveDetailViewModel: ObservableObject {
    @Published var posts: [ArchivePost] = []
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
    
    init(roomId: String, date: Date) {
        self.roomId = roomId
        self.date = date
        Task { await fetchDailyPosts() }
    }
    
    func fetchDailyPosts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return
            }
            
            let query = db.collection("Rooms")
                .document(roomId)
                .collection("posts")
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("createdAt", isLessThan: Timestamp(date: endOfDay))
                .order(by: "createdAt", descending: false)
            
            let snapshot = try await query.getDocuments()
            
            let mapped: [ArchivePost] = snapshot.documents.compactMap { doc in
                let data = doc.data()
                
                let tsCreated = data["createdAt"] as? Timestamp
                let tsUpdated = data["updatedAt"] as? Timestamp
                
                let caption = data["caption"] as? String
                let stickerPostId = data["stickerPostId"] as? String
                let stickerTypeString = (data["stickerType"] as? String)?.lowercased()
                let stickerType: StickerType? = {
                    guard let s = stickerTypeString, s != "null" else { return nil }
                    return StickerType(rawValue: s)
                }()
                
                return ArchivePost(
                    id: doc.documentID,
                    createdAt: tsCreated?.dateValue() ?? .distantPast,
                    updatedAt: tsUpdated?.dateValue() ?? tsCreated?.dateValue() ?? .distantPast,
                    authorName: (data["authorName"] as? String) ?? (data["authorId"] as? String),
                    frontImageURL: (data["frontImageURL"] as? String).flatMap(URL.init(string:)),
                    backImageURL:  (data["backImageURL"]  as? String).flatMap(URL.init(string:)),
                    caption: caption,
                    stickerPostId: stickerPostId,
                    stickerType: stickerType
                )
            }
            self.posts = mapped
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
