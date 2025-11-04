//
//  SitckerCollectionViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/4/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import Kingfisher
import PhotosUI
import SwiftUI

final class SitckerCollectionViewModel: ObservableObject {
    @Published var selectedCategory: StickerCategory = .affection
    @Published var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    
    @Published var showMakeStickerButton: Bool = false
    @Published var targetItemID: StickerItem.ID?
    
    @Published var showPhotoPicker: Bool = false
    @Published var pickedPhotoItem: PhotosPickerItem?
    @Published var showCamera: Bool = false
    @Published var capturedImage: UIImage?
    
    @Published var remoteURLByItemID: [StickerItem.ID: URL] = [:]
    @Published var loadingItemIDs: Set<StickerItem.ID> = []
    
    let actionBarAnimDuration: Double = 0.25
    private let dataManager: DataManagerProtocol = DataManager.shared
    
    func returnStickerItems(for category: StickerCategory) -> [StickerItem] {
        itemsByCategory[category] ?? []
    }
    
    // TODO: 갤러리에서 사진 선택시 업데이트하는 함수, 추후 수정
    @MainActor
    func handlePickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self), let uiImg = UIImage(data: data), var arr = itemsByCategory[selectedCategory], let id = targetItemID, let index = arr.firstIndex(where: { $0.id == id }) {
                var edited = arr[index]
                edited.image = uiImg
                arr[index] = edited
                itemsByCategory[selectedCategory] = arr
                
                showMakeStickerButton = false
                targetItemID = nil            }
        } catch {
            // 에러 처리 추가
        }
    }
    
    func fetchStickerImage(forID id: StickerItem.ID) async {
        guard let item = itemsByCategory[selectedCategory]?.first(where: { $0.id == id }) else { return }
        
        loadingItemIDs.insert(item.id)
        // TODO: 추후 스티커 컬렉션 뷰와 메인뷰 연결 후, 싱글톤 적용
        guard let uid = Auth.auth().currentUser?.uid else {
            loadingItemIDs.remove(item.id)
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
            print("❌ 스티커 이미지 로드 실패: \(error)")
        }
        loadingItemIDs.remove(item.id)
    }
}
