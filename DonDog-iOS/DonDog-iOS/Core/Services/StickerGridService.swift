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
    
    @Published var stickerImageURLs: [StickerItem.ID: URL] = [:]
    @Published var loadingItemIDs: Set<StickerItem.ID> = []
    
    @Published var selectedCategory: StickerCategory = .affection
    @Published var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    
    private init() {}
    
    func stickerItems(for category: StickerCategory) -> [StickerItem] {
        itemsByCategory[category] ?? []
    }

    func fetchStickerImage(for item: StickerItem, in category: StickerCategory) async {
        loadingItemIDs.insert(item.id)
        defer { loadingItemIDs.remove(item.id) }

        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let stickers: [StickerData] = try await DataManager.shared.fetchWhereEqual(
                path: "Stickers",
                field: "uid",
                isEqualTo: uid
            )

            let tags = [category.rawValue, item.title]
            let filtered = stickers.filter { $0.emotionTags == tags }
            let latest = filtered.max { lhs, rhs in
                let lhsDate = lhs.createdAt
                let rhsDate = rhs.createdAt
                return lhsDate < rhsDate
            }

            if let latest,
               let url = URL(string: latest.url) {
                stickerImageURLs[item.id] = url
            }
        } catch {
            print("❌ 스티커 이미지 로드 실패: \(error)")
        }
    }
}
