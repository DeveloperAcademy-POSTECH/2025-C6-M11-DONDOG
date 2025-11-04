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

final class StickerEmotionTagManager {
    static let shared = StickerEmotionTagManager()
    private init() {}
    
    var emotionTags: [String] = []
}

struct SitckerCollectionView: View {
    @StateObject var viewModel: SitckerCollectionViewModel
    @StateObject private var cameraVM = CameraViewModel()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack {
            categoryTabs
                .padding(.vertical, 12)
            
            LazyVGrid(columns: columns) {
                ForEach(viewModel.returnStickerItems(for: viewModel.selectedCategory)) { item in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.06))
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                                )

                            if let url = viewModel.remoteURLByItemID[item.id] {
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
                                if viewModel.loadingItemIDs.contains(item.id) {
                                    EmptyView()
                                } else {
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
                    .task {
                        await viewModel.fetchStickerImage(forID: item.id)
                    }
                    .onChange(of: viewModel.showCamera) { _, isPresented in
                        if isPresented == false {
                            Task { await viewModel.fetchStickerImage(forID: item.id) }
                        }
                    }
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            guard let tappedItem = viewModel.itemsByCategory[viewModel.selectedCategory]?.first(where: { $0.id == item.id }) else { return }
                            /// 이미 같은 셀을 다시 탭한 상황이면 무시 (액션바가 떠 있는 상태에서의 중복 방지)
                            if viewModel.showMakeStickerButton, viewModel.targetItemID == tappedItem.id { return }
                            viewModel.targetItemID = tappedItem.id
                            StickerEmotionTagManager.shared.emotionTags = [viewModel.selectedCategory.rawValue, tappedItem.title]
                            withAnimation(.easeInOut(duration: viewModel.actionBarAnimDuration)) {
                                viewModel.showMakeStickerButton = true
                            }
                        }
                    )
                }
            }
            
            Spacer()
            
            if viewModel.showMakeStickerButton {
                makeStickerButton
            }
        }
        .padding(.horizontal, 12)
        .background(dismissBackdrop)
        .simultaneousGesture(
            /// 뷰 전체에 탭 제스처 추가 - 화면 빈 곳을 탭하면 버튼을 닫기 위함
            TapGesture().onEnded {
                if viewModel.showMakeStickerButton {
                    viewModel.showMakeStickerButton = false
                }
            }
        )
        .photosPicker(
            isPresented: $viewModel.showPhotoPicker,
            selection: $viewModel.pickedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: viewModel.pickedPhotoItem) {
            Task { await viewModel.handlePickedPhoto(viewModel.pickedPhotoItem) }
        }
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            CameraView(viewModel: cameraVM)
                .ignoresSafeArea()
        }
            
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
                    let list = viewModel.itemsByCategory[viewModel.selectedCategory],
                    let item = list.first(where: { $0.id == id })
                else {
                    return
                }
                let keyword = item.title
                StickerEmotionTagManager.shared.emotionTags = [viewModel.selectedCategory.rawValue, keyword]
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
}

#Preview {
    SitckerCollectionView(viewModel: SitckerCollectionViewModel())
}
