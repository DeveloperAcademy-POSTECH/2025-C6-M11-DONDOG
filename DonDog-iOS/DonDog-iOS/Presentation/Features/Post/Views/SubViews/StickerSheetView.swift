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
    @ObservedObject var viewModel: StickerViewModel
    let postId: String
    
    @State private var select = 0
    @Environment(\.dismiss) var dismiss
    private let categories = StickerCategory.allCases
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
    @StateObject private var cameraVM = CameraViewModel()
    @ObservedObject private var gridService: StickerGridService
    init(viewModel: StickerViewModel, postId: String, gridService: StickerGridService = .shared) {
        self.viewModel = viewModel
        self.postId = postId
        self._gridService = ObservedObject(wrappedValue: gridService)
    }

    var body: some View {
        NavigationStack {
            VStack {
                StickerGrid(
                    items: gridService.stickerItems(for: gridService.selectedCategory),
                    remoteURLByItemID: gridService.stickerImageURLs,
                    loadingItemIDs: gridService.loadingItemIDs,
                    columns: columns,
                    rowSpacing: 8,
                    isCameraPresented: $viewModel.showCamera,
                    onItemAppear: { id in
                        if let item = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == id }) {
                            Task { await gridService.fetchStickerImage(for: item, in: gridService.selectedCategory) }
                        }
                    },
                    onItemTap: { item in
                        if let url = gridService.stickerImageURLs[item.id] {
                            viewModel.targetItemID = item.id
                            viewModel.addSticker(with: url)
                        }
                    },
                    onPlusTap: { item in
                        StickerEmotionTagManager.shared.emotionTags = [gridService.selectedCategory.rawValue, item.title]
                        viewModel.targetItemID = item.id
                        cameraVM.isFrontOnly = true
                        cameraVM.stickerKeyword = item.title
                        cameraVM.resetCameraState()
                        viewModel.showCamera = true
                    },
                    onCameraDismiss: { id in
                        if let item = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == id }) {
                            Task { await gridService.fetchStickerImage(for: item, in: gridService.selectedCategory) }
                        }
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $select) {
                        ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                            Text(category.rawValue).tag(index)
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
                        Task {
                            await viewModel.saveStickers()
                            viewModel.selectedStickerID = nil
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline)
                    }
                }
            }
        }
        .cameraCaptureFlow(isPresented: $viewModel.showCamera, cameraVM: cameraVM)
    }
}
