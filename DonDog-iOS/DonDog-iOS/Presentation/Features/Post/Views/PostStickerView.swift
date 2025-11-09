//
//  PostStickerView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUI

// 스티커 카테고리와 공용 컴포넌트 StickerGrid 사용 방법을 알려주기 위한 연습 뷰 for Hyun.. 추후 삭제 요망
struct PostStickerView: View {
    // 뷰모델에서 선언 (State -> Published로 변경)
    @State private var selectedCategory: StickerCategory = .affection
    @State private var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    @State private var showCamera = false
    @State private var targetItemID: StickerItem.ID?
    @State private var previewURL: URL?
    
    func items(for category: StickerCategory) -> [StickerItem] {
        itemsByCategory[category] ?? []
    }
    
    // 뷰에서 선언
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    @StateObject private var cameraVM = CameraViewModel()
    @ObservedObject private var gridService: StickerGridService
    init(gridService: StickerGridService = .shared) {
        self._gridService = ObservedObject(wrappedValue: gridService)
    }

    // 뷰 body
    var body: some View {
        // 여기서 수정/삭제/크기 조절 기능 추가
        if let url = previewURL {
            KFImage(url)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
        }
        
        HStack {
            let categories = StickerCategory.allCases
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                Text(category.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .onTapGesture {
                        selectedCategory = category
                        targetItemID = nil
                        previewURL = nil
                    }
                if index < categories.count - 1 { Spacer(minLength: 0) }
            }
        }

        StickerGrid(
            items: items(for: selectedCategory),
            remoteURLByItemID: gridService.remoteURLByItemID,
            loadingItemIDs: gridService.loadingItemIDs,
            columns: columns,
            isCameraPresented: $showCamera,
            onItemAppear: { id in
                if let item = items(for: selectedCategory).first(where: { $0.id == id }) {
                    Task { await gridService.fetchStickerImage(for: item, in: selectedCategory) }
                }
            },
            onItemTap: { item in
                if let url = gridService.remoteURLByItemID[item.id] {
                    previewURL = url
                    targetItemID = item.id
                }
            },
            onPlusTap: { item in
                StickerEmotionTagManager.shared.emotionTags = [selectedCategory.rawValue, item.title]
                targetItemID = item.id
                cameraVM.isFrontOnly = true
                cameraVM.resetCameraState()
                showCamera = true
            },
            onCameraDismiss: { id in
                if let item = items(for: selectedCategory).first(where: { $0.id == id }) {
                    Task { await gridService.fetchStickerImage(for: item, in: selectedCategory) }
                }
            }
        )
        // 뷰 최상단에 선언 (카메라 뷰 full screen)
        .cameraCaptureFlow(isPresented: $showCamera, cameraVM: cameraVM)
    }
}
