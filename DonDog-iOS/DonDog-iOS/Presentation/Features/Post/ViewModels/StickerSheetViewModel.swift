//
//  StickerSheetViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 11/7/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import Kingfisher
import PhotosUI
import SwiftUI

final class StickerSheetViewModel: ObservableObject {
    @Published var selectedCategory: StickerCategory = .affection
    @Published var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    
    @Published var remoteURLByItemID: [StickerItem.ID: URL] = [:]
    @Published var loadingItemIDs: Set<StickerItem.ID> = []
    
    private let dataManager: DataManagerProtocol = DataManager.shared
    private let connectUserInfo = UserPairingStore.shared
    
    func returnStickerItems(for category: StickerCategory) -> [StickerItem] {
        itemsByCategory[category] ?? []
    }
    
    func fetchStickerImage(forID id: StickerItem.ID) async {
        guard let item = itemsByCategory[selectedCategory]?.first(where: { $0.id == id }) else { return }
        
        guard let uid = connectUserInfo.myUid else {
            print("user id 로드 실패")
            return
        }
        
        do {
            let stickers: [StickerData] = try await DataManager.shared.fetchWhereEqual(
                path: "Stickers",
                field: "uid",
                isEqualTo: uid
            )
            if let match = stickers.first(where: { $0.emotionTags == [selectedCategory.rawValue, item.title] }), let url = URL(string: match.url) {
                remoteURLByItemID[item.id] = url
            }
        } catch {
            print("스티커 이미지 로드 실패: \(error)")
        }
        loadingItemIDs.remove(item.id)
    }
}
