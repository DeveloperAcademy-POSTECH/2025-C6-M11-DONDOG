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

// 스티커 카테고리와 공용 컴포넌트 StickerGrid 사용 방법을 알려주기 위한 연습 뷰 for Hyun.. 추후 삭제 요망
struct StickerSheetView: View {
    @ObservedObject var viewModel: StickerViewModel
    @State private var select = 0
    @Environment(\.dismiss) var dismiss
    private let categories = StickerCategory.allCases
    
    // 뷰에서 선언
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3) // 스티커 사이 간격 여기서 조절
    @StateObject private var cameraVM = CameraViewModel()
    @ObservedObject private var gridService: StickerGridService
    init(viewModel: StickerViewModel, gridService: StickerGridService = .shared) {
        self.viewModel = viewModel
        self._gridService = ObservedObject(wrappedValue: gridService)
    }

    // 뷰 body
    var body: some View {
        //        // 여기서 수정/삭제/크기 조절 기능 추가
        //        if let url = previewURL {
        //            KFImage(url)
        //                .resizable()
        //                .scaledToFit()
        //                .frame(maxWidth: .infinity)
        //                .padding(.bottom, 8)
        //        }
        //        
        //        HStack {
        //            let categories = StickerCategory.allCases
        //            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
        //                Text(category.rawValue)
        //                    .font(.system(size: 15, weight: .semibold))
        //                    .padding(.horizontal, 14)
        //                    .padding(.vertical, 8)
        //                    .onTapGesture {
        //                        gridService.selectedCategory = category
        //                        targetItemID = nil
        //                        previewURL = nil
        //                    }
        //                if index < categories.count - 1 { Spacer(minLength: 0) }
        //            }
        //        }
        
        NavigationStack {
            VStack {
                StickerGrid(
                    items: gridService.stickerItems(for: gridService.selectedCategory),
                    remoteURLByItemID: gridService.stickerImageURLs,
                    loadingItemIDs: gridService.loadingItemIDs,
                    columns: columns,
                    rowSpacing: 8, // 스티커 줄 사이 간격 여기서 조절
                    isCameraPresented: $viewModel.showCamera,
                    onItemAppear: { id in
                        if let item = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == id }) {
                            Task { await gridService.fetchStickerImage(for: item, in: gridService.selectedCategory) }
                        }
                    },
                    onItemTap: { item in
                        if let url = gridService.stickerImageURLs[item.id] {
                            //                    previewURL = url
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
                        print("selectedCategory: \(gridService.selectedCategory)")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.saveStickers()
                        viewModel.selectedStickerID = nil
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline)
                    }
                }
            }
        }
        // 뷰 최상단에 선언 (카메라 뷰 full screen)
        .cameraCaptureFlow(isPresented: $viewModel.showCamera, cameraVM: cameraVM)
    }
}
