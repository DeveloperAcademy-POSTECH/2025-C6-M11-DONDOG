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
    
    @Published var stickerURLCache: [StickerItem.ID: URL] = [:]
    @Published var loadingSet: Set<StickerItem.ID> = []
    
    let actionBarAnimDuration: Double = 0.25
    
    func items(for category: StickerCategory) -> [StickerItem] {
        itemsByCategory[category] ?? []
    }
    
    func updateItemImage(_ image: UIImage) {
        guard var arr = itemsByCategory[selectedCategory], let id = targetItemID, let index = arr.firstIndex(where: { $0.id == id }) else { return }
        var edited = arr[index]
        edited.image = image
        arr[index] = edited
        itemsByCategory[selectedCategory] = arr
    }
    
    func applySelectedImage(_ image: UIImage) {
        updateItemImage(image)
        showMakeStickerButton = false
        targetItemID = nil
    }
    
    @MainActor
    func handlePickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self), let uiImg = UIImage(data: data) {
                applySelectedImage(uiImg)
            }
        } catch {
            // TODO: 에러 처리 추가
        }
    }
    
    func refreshStickerAfterReturn() {
        guard let id = targetItemID, let list = itemsByCategory[selectedCategory], let item = list.first(where: { $0.id == id }) else { return }
        stickerURLCache[id] = nil
        loadingSet.remove(id)
        fetchStickerURL(for: item)
    }
    
    func fetchStickerURL(for item: StickerItem) {
        if stickerURLCache[item.id] != nil || loadingSet.contains(item.id) { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        loadingSet.insert(item.id)
        let db = Firestore.firestore()
        db.collection("Stickers")
            .whereField("uid", isEqualTo: uid)
            .whereField("emotionTags", isEqualTo: [selectedCategory.rawValue, item.title])
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.loadingSet.remove(item.id)
                    if let docs = snapshot?.documents, let first = docs.first, let urlString = first.data()["url"] as? String, let url = URL(string: urlString) {
                        self.stickerURLCache[item.id] = url
                    }
                }
            }
    }
}
