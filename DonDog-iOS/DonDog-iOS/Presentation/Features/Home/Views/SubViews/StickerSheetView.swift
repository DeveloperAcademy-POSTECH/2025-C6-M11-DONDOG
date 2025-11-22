//
//  StickerSheetView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUI

struct StickerSheetView: View {
    @ObservedObject var stickerViewModel: StickerViewModel
    let postId: String
    let onRequestCamera: () -> Void
    
    @State private var select: Int
    @Environment(\.dismiss) var dismiss
    private let categories = StickerCategory.allCases
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: -10), count: 3)
    @StateObject private var cameraVM = CameraViewModel()
    @ObservedObject private var gridService: StickerGridService
    
    init(
        stickerViewModel: StickerViewModel,
        postId: String,
        onRequestCamera: @escaping () -> Void,
        gridService: StickerGridService
    ) {
        self.stickerViewModel = stickerViewModel
        self.postId = postId
        self.onRequestCamera = onRequestCamera
        self._gridService = ObservedObject(wrappedValue: gridService)
        
        let allCategories = StickerCategory.allCases
        let initialIndex = allCategories.firstIndex(of: gridService.selectedCategory) ?? 0
        self._select = State(initialValue: initialIndex)
    }

    var body: some View {
        NavigationStack {
            VStack {
                StickerGrid(
                    showedAt: .sheet,
                    items: gridService.stickerItems(for: gridService.selectedCategory),
                    remoteURLByItemID: gridService.stickerImageURLs,
                    loadingItemIDs: gridService.loadingItemIDs,
                    columns: columns,
                    rowSpacing: 8,
                    onItemAppear: { id in
                        guard gridService.stickerImageURLs[id] == nil, gridService.loadingItemIDs.contains(id) == false, let item = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == id }) else { return }
                        
                        Task {
                            await gridService.fetchStickerImage(for: item, in: gridService.selectedCategory)
                        }
                    },
                    onItemTap: { item in
                        if let url = gridService.stickerImageURLs[item.id] {
                            stickerViewModel.targetItemID = item.id
                            stickerViewModel.addSticker(with: url)
                        }
                    },
                    onPlusTap: { item in
                        let keyword = item.title
                        StickerEmotionTagManager.shared.emotionTags = [
                            gridService.selectedCategory.rawValue,
                            keyword
                        ]
                        onRequestCamera()
                    },
                    categoryKey: gridService.selectedCategory.assetKey,
                    role: UserPairingStore.shared.myRole
                )
                .hapticFeedback(.heavy)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("", selection: $select) {
                            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                                Text(category.rawValue)
                                    .font(.bodyRegular16)
                                    .foregroundColor(.ppWhite)
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 300)
                        .onChange(of: select) { _, selectedValue in
                            gridService.selectedCategory = categories[selectedValue]
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                            Task {
                                await stickerViewModel.saveStickers()
                            }
                            stickerViewModel.selectedStickerID = nil
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.captionRegular13)
                                .foregroundColor(.ppWhite)
                        }
                        .hapticFeedback(.light)
                    }
                }
            }
        }
    }
}
