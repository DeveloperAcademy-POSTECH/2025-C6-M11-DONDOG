//
//  SitckerCollectionView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/1/25.
//

import Combine
import Kingfisher
import SwiftUI

final class StickerEmotionTagManager {
    static let shared = StickerEmotionTagManager()
    private init() {}
    
    var emotionTags: [String] = []
}

struct SitckerCollectionView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: SitckerCollectionViewModel
    @StateObject private var cameraVM = CameraViewModel()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    @ObservedObject private var gridService: StickerGridService
    init(viewModel: SitckerCollectionViewModel, gridService: StickerGridService = .shared) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._gridService = ObservedObject(wrappedValue: gridService)
    }

    var body: some View {
        VStack {
            CustomNavigationBar(leadingType: .back(action: { coordinator.pop() }), centerType: .title(title: "스티커 만들기"), trailingType: .none, navigationColor: .black)
            
            categoryTabs
                .padding(.vertical, 6)
            
            StickerGrid(
                items: gridService.stickerItems(for: gridService.selectedCategory),
                remoteURLByItemID: gridService.stickerImageURLs,
                loadingItemIDs: gridService.loadingItemIDs,
                columns: columns,
                rowSpacing: 40,
                isCameraPresented: $viewModel.showCamera,
                isStickerConfirmPresented: $viewModel.showStickerConfirm,
                onItemAppear: { id in
                    if let item = gridService.stickerItems(for: gridService.selectedCategory)
                        .first(where: { $0.id == id }) {
                        Task { await gridService.fetchStickerImage(for: item, in: gridService.selectedCategory) }
                    }
                },
                onItemTap: { item in
                    guard let tapped = gridService.stickerItems(for: gridService.selectedCategory)
                        .first(where: { $0.id == item.id }) else { return }
                    if viewModel.showMakeStickerButton, viewModel.targetItemID == tapped.id { return }
                    viewModel.targetItemID = tapped.id
                    StickerEmotionTagManager.shared.emotionTags = [gridService.selectedCategory.rawValue, tapped.title]
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.showMakeStickerButton = true
                    }
                },
                onCameraDismiss: { id in
                    if let item = gridService.stickerItems(for: gridService.selectedCategory)
                        .first(where: { $0.id == id }) {
                        Task { await gridService.fetchStickerImage(for: item, in: gridService.selectedCategory) }
                    }
                },
                onConfirmDismiss: { id in
                    if let item = gridService.stickerItems(for: gridService.selectedCategory)
                        .first(where: { $0.id == id }) {
                        Task { await gridService.fetchStickerImage(for: item, in: gridService.selectedCategory) }
                    }
                },
                selectedItemID: viewModel.targetItemID
            )
            
            Spacer()
            
            if viewModel.showMakeStickerButton {
                makeStickerButton
            }
        }
        .padding(.horizontal, 12)
        .backHiddenSwipeEnabled()
        .background(dismissBackdrop)
        .simultaneousGesture(
            /// 뷰 전체에 탭 제스처 추가 - 화면 빈 곳을 탭하면 버튼을 닫기 위함
            TapGesture().onEnded {
                if viewModel.showMakeStickerButton {
                    viewModel.showMakeStickerButton = false
                }
            }
        )
        .cameraCaptureFlow(isPresented: $viewModel.showCamera, cameraVM: cameraVM)
        .photoPickerStickerConfirmFlow(viewModel: viewModel)
    }
    
    private var makeStickerButton: some View {
        HStack {
            Button {
                viewModel.showPhotoPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                    Text("기존 게시물\n사진으로 만들기")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .border(Color.black, width: 1)
            }
            
            Spacer()
            
            Button {
                guard
                    let id = viewModel.targetItemID,
                    let item = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == id })
                else {
                    return
                }
                let keyword = item.title
                StickerEmotionTagManager.shared.emotionTags = [gridService.selectedCategory.rawValue, keyword]
                cameraVM.stickerKeyword = keyword
                cameraVM.isFrontOnly = true
                cameraVM.resetCameraState()
                viewModel.showCamera = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera")
                    Text("사진 찍기")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .border(Color.black, width: 1)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var dismissBackdrop: some View {
        Group {
            if viewModel.showMakeStickerButton {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.showMakeStickerButton = false
                        viewModel.targetItemID = nil
                    }
            }
        }
    }

    private var categoryTabs: some View {
        HStack {
            let categories = StickerCategory.allCases
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                let isSelected = category == gridService.selectedCategory
                Text(category.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? Color.primary.opacity(0.1) : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
                    .onTapGesture {
                        gridService.selectedCategory = category
                        viewModel.showMakeStickerButton = false
                        viewModel.targetItemID = nil
                    }
                if index < categories.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview {
    SitckerCollectionView(viewModel: SitckerCollectionViewModel())
}
