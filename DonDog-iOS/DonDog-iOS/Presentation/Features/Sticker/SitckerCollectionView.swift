//
//  SitckerCollectionView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/1/25.
//

import Combine
import PhotosUI
import SwiftUI

struct SitckerCollectionView: View {
    @State private var selectedCategory: StickerCategory = .affection
    @State private var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    @StateObject private var cameraVM = CameraViewModel()

    @State private var showMakeStickerButton: Bool = false
    @State private var targetItemID: StickerItem.ID?

    @State private var showPhotoPicker: Bool = false
    @State private var pickedPhotoItem: PhotosPickerItem?
    @State private var showCamera: Bool = false
    @State private var capturedImage: UIImage?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let actionBarAnimDuration: Double = 0.25

    var body: some View {
        let base = mainContent
            .background(dismissBackdrop)

        return base
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $pickedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: pickedPhotoItem) { _, newValue in
                Task { await handlePickedPhoto(newValue) }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(viewModel: cameraVM)
                .ignoresSafeArea()
            }
    }

    private var mainContent: some View {
        VStack {
            categoryTabs
                .padding(.vertical, 12)
            
            LazyVGrid(columns: columns) {
                ForEach(items(for: selectedCategory)) { item in
                    stickerCell(item)
                }
            }
            
            Spacer()
            
            if showMakeStickerButton {
                HStack {
                    Button {
                        showPhotoPicker = true
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
                        let keyword: String = {
                            if let id = targetItemID,
                               let list = itemsByCategory[selectedCategory],
                               let item = list.first(where: { $0.id == id }) {
                                return item.title
                            } else {
                                return selectedCategory.rawValue
                            }
                        }()
                        cameraVM.stickerKeyword = keyword
                        cameraVM.isFrontOnly = true
                        cameraVM.resetCameraState()
                        showCamera = true
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
        .animation(.easeInOut, value: showMakeStickerButton)
        .simultaneousGesture(
            TapGesture().onEnded {
                if showMakeStickerButton {
                    showMakeStickerButton = false
                    targetItemID = nil
                }
            }
        )
    }

    private var dismissBackdrop: some View {
        Group {
            if showMakeStickerButton {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showMakeStickerButton = false
                        targetItemID = nil
                    }
            }
        }
    }

    private var categoryTabs: some View {
        HStack {
            let categories = StickerCategory.allCases
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                let isSelected = category == selectedCategory
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
                        selectedCategory = category
                        showMakeStickerButton = false
                        targetItemID = nil
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

                if let image = item.image {
                    // 누끼/꾸미기 완료된 스티커
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
                if showMakeStickerButton {
                    if targetItemID == item.id { return }
                    withAnimation(.easeInOut(duration: actionBarAnimDuration)) {
                        showMakeStickerButton = false
                    }
                    let newID = item.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + actionBarAnimDuration * 0.9) {
                        targetItemID = newID
                        withAnimation(.easeInOut(duration: actionBarAnimDuration)) {
                            showMakeStickerButton = true
                        }
                    }
                } else {
                    targetItemID = item.id
                    withAnimation(.easeInOut(duration: actionBarAnimDuration)) {
                        showMakeStickerButton = true
                    }
                }
            }
        )
    }

    // MARK: - Helpers
    private func items(for category: StickerCategory) -> [StickerItem] {
        itemsByCategory[category] ?? []
    }

    private func updateItemImage(_ image: UIImage) {
        guard var arr = itemsByCategory[selectedCategory], let id = targetItemID, let index = arr.firstIndex(where: { $0.id == id }) else { return }
        var edited = arr[index]
        // TODO: 추후 "누끼 따기 (background removal)" 처리 후 결과 이미지를 대입
        edited.image = image
        arr[index] = edited
        itemsByCategory[selectedCategory] = arr
    }

    private func applySelectedImage(_ image: UIImage) {
        // 여기서 실제 누끼 처리 로직(서버/온디바이스)을 붙이면 됨.
        updateItemImage(image)
        showMakeStickerButton = false
        targetItemID = nil
    }

    private func handlePickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self), let uiImg = UIImage(data: data) {
                applySelectedImage(uiImg)
            }
        } catch {
            // 필요 시 오류 처리
        }
    }
}

#Preview {
    SitckerCollectionView()
}
