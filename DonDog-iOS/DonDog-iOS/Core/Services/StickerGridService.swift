//
//  StickerGridService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

final class StickerGridService: ObservableObject {
    static let shared = StickerGridService()
    
    @Published private(set) var role: String
    @Published var stickerImageURLs: [StickerItem.ID: URL] = [:]
    @Published var loadingItemIDs: Set<StickerItem.ID> = []
    
    @Published var selectedCategory: StickerCategory = .bigEmotion
    @Published var itemsByCategory: [StickerCategory: [StickerItem]]
    
    var fetchedItemIDs: Set<StickerItem.ID> = []
    
    init(role: String? = nil) {
        let resolvedRole = role ?? UserPairingStore.shared.myRole ?? "child"
        self.role = resolvedRole
        self.itemsByCategory = StickerCategoryData.itemsByCategory(for: resolvedRole)
    }
    
    func stickerItems(for category: StickerCategory) -> [StickerItem] {
        let items = itemsByCategory[category] ?? []
        return items
    }
    
    func fetchStickerImage(for item: StickerItem, in category: StickerCategory) async {
        if fetchedItemIDs.contains(item.id) { return }
        
        loadingItemIDs.insert(item.id)
        stickerImageURLs[item.id] = nil
        defer {
            loadingItemIDs.remove(item.id)
            fetchedItemIDs.insert(item.id)
        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let stickers: [StickerData] = try await DataManager.shared.fetchWhereEqual(
                path: "Stickers",
                field: "authorUid",
                isEqualTo: uid
            )
            
            let roleFiltered = stickers.filter { $0.authorRole == self.role }
            let tags = [category.rawValue, item.title]
            let filtered = roleFiltered.filter { $0.emotionTags == tags }
            let latest = filtered.max { lhs, rhs in
                let lhsDate = lhs.createdAt
                let rhsDate = rhs.createdAt
                return lhsDate < rhsDate
            }
            
            if let latest, let url = URL(string: latest.stickerURL) {
                stickerImageURLs[item.id] = url
            }
        } catch {
            print("❌ 스티커 이미지 로드 실패: \(error)")
        }
    }
    
    func reloadSticker(tags: [String]) async {
        guard tags.count >= 2 else { return }
        let categoryRaw = tags[0]
        let title = tags[1]
        
        guard let category = StickerCategory(rawValue: categoryRaw) else { return }
        
        let items = stickerItems(for: category)
        guard let item = items.first(where: { $0.title == title }) else { return }
        
        fetchedItemIDs.remove(item.id)
        await fetchStickerImage(for: item, in: category)
    }
    
    func deleteCache() {
        stickerImageURLs.removeAll()
        loadingItemIDs.removeAll()
        fetchedItemIDs.removeAll()
    }
    
    func updateRole() {
        let resolvedRole = UserPairingStore.shared.myRole ?? "child"
        role = resolvedRole
        itemsByCategory = StickerCategoryData.itemsByCategory(for: resolvedRole)
    }
}
