//
//  SitckerCollectionView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/1/25.
//

import Combine
import Kingfisher
import PhotosUI
import SwiftUI

final class StickerTagManager {
    static let shared = StickerTagManager()
    private init() {}
    
    var emotionTags: [String] = []
}

struct SitckerCollectionView: View {
    @StateObject var viewModel: SitckerCollectionViewModel
    
    @StateObject private var cameraVM = CameraViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        let base = mainContent
            .background(dismissBackdrop)

        return base
            .photosPicker(
                isPresented: $viewModel.showPhotoPicker,
                selection: $viewModel.pickedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: viewModel.pickedPhotoItem) {
                Task { await viewModel.handlePickedPhoto(viewModel.pickedPhotoItem) }
            }
            .fullScreenCover(
                isPresented: $viewModel.showCamera,
                onDismiss: {
                    viewModel.refreshStickerAfterReturn()
                },
                content: {
                    CameraView(viewModel: cameraVM)
                        .ignoresSafeArea()
                }
            )
    }

    private var mainContent: some View {
        VStack {
            categoryTabs
                .padding(.vertical, 12)
            
            LazyVGrid(columns: columns) {
                ForEach(viewModel.items(for: viewModel.selectedCategory)) { item in
                    stickerCell(item)
                }
            }
            
            Spacer()
            
            if viewModel.showMakeStickerButton {
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
                            let list = viewModel.itemsByCategory[viewModel.selectedCategory],
                            let item = list.first(where: { $0.id == id })
                        else {
                            // 선택된 아이템이 없으면 촬영을 막아 잘못된 기본값 저장을 방지
                            return
                        }
                        let keyword = item.title
                        StickerTagManager.shared.emotionTags = [viewModel.selectedCategory.rawValue, keyword]
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
        }
        .padding(.horizontal, 12)
        .animation(.easeInOut, value: viewModel.showMakeStickerButton)
        .simultaneousGesture(
            TapGesture().onEnded {
                if viewModel.showMakeStickerButton {
                    viewModel.showMakeStickerButton = false
                }
            }
        )
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
                let isSelected = category == viewModel.selectedCategory
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
                        viewModel.selectedCategory = category
                        viewModel.showMakeStickerButton = false
                        viewModel.targetItemID = nil
                    }
                if index < categories.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder
    private func stickerCell(_ item: StickerItem) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.06))
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                    )

                if let url = viewModel.stickerURLCache[item.id] {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 28, weight: .semibold))
                    }
                }
            }
            Text(item.title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            TapGesture().onEnded {
                if viewModel.showMakeStickerButton {
                    if viewModel.targetItemID == item.id { return }
                    // 선택 즉시 적용하여 버튼 탭 시 잘못된 기본값을 쓰지 않도록 함
                    viewModel.targetItemID = item.id
                    StickerTagManager.shared.emotionTags = [viewModel.selectedCategory.rawValue, item.title]
                    
                    withAnimation(.easeInOut(duration: viewModel.actionBarAnimDuration)) {
                        viewModel.showMakeStickerButton = true
                    }
                } else {
                    viewModel.targetItemID = item.id
                    StickerTagManager.shared.emotionTags = [viewModel.selectedCategory.rawValue, item.title]
                    withAnimation(.easeInOut(duration: viewModel.actionBarAnimDuration)) {
                        viewModel.showMakeStickerButton = true
                    }
                }
            }
        )
        .onAppear {
            viewModel.fetchStickerURL(for: item)
        }
    }
}

#Preview {
    SitckerCollectionView(viewModel: SitckerCollectionViewModel())
}
