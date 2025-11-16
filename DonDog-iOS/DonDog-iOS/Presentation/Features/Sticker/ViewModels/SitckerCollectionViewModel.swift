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
    @Published var showMakeStickerButton: Bool = false
    @Published var targetItemID: StickerItem.ID?
    
    @Published var pickedImage: UIImage?
    @Published var capturedImage: UIImage?
    
    private let dataManager: DataManagerProtocol = DataManager.shared
    
    func reloadStickerIfNeeded() {
        let tags = StickerEmotionTagManager.shared.emotionTags
        guard tags.count >= 2 else { return }
        
        let categoryRaw = tags[0]
        let title = tags[1]
        
        guard let category = StickerCategory(rawValue: categoryRaw) else {
            StickerEmotionTagManager.shared.emotionTags = []
            return
        }
        
        let items = StickerGridService().stickerItems(for: category)
        guard let item = items.first(where: { $0.title == title }) else {
            StickerEmotionTagManager.shared.emotionTags = []
            return
        }
        
        Task {
            await StickerGridService().fetchStickerImage(for: item, in: category)
            await MainActor.run {
                StickerEmotionTagManager.shared.emotionTags = []
            }
        }
    }
}
