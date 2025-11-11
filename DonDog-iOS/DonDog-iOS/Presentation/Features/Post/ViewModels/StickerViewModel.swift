//
//  StickerViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 11/7/25.
//

import Combine
import CoreGraphics
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct AttachedSticker: Identifiable, Codable {
    var id = UUID()
    var imageName: String
    var position: CGPoint
    var scale: CGFloat
    var rotation: Angle
}

final class StickerViewModel: ObservableObject {
    @Published var selectedCategory: StickerCategory = .affection
    @Published var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    
    @Published var remoteURLByItemID: [StickerItem.ID: URL] = [:]
    @Published var loadingItemIDs: Set<StickerItem.ID> = []
    
    private let dataManager: DataManagerProtocol = DataManager.shared
    private let connectUserInfo = UserPairingStore.shared
    
    @Published var stickers: [AttachedSticker] = []
    @Published var selectedStickerID: UUID?
    
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
    
    func addSticker(named imageName: String) {
        let newSticker = AttachedSticker(
            imageName: imageName,
            position: .zero,
            scale: 1.0,
            rotation: .zero
        )
        stickers.append(newSticker)
        selectedStickerID = newSticker.id
    }
    
    func removeSticker(_ sticker: AttachedSticker) {
        stickers.removeAll { $0.id == sticker.id }
    }
    
    func saveStickers() {
        // print()로 상태 출력
        print("===== StickerData 상태 =====")
        for s in stickers {
            print("ID: \(s.id)")
            print("Image: \(s.imageName)")
            print("Position: \(s.position)")
            print("Scale: \(s.scale)")
            print("Rotation: \(s.rotation.degrees)°")
            print("---------------------------")
        }
        print("============================\n")
        
        if let encoded = try? JSONEncoder().encode(stickers) {
            UserDefaults.standard.set(encoded, forKey: "savedStickers")
        }
    }
    
    func loadSavedStickers() {
        if let data = UserDefaults.standard.data(forKey: "savedStickers"),
            let decoded = try? JSONDecoder().decode([AttachedSticker].self, from: data) {
            stickers = decoded
        }
    }
}
