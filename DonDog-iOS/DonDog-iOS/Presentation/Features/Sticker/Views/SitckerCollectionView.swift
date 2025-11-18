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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: -10), count: 3)
    @Namespace private var categoryUnderlineNamespace
    
    @ObservedObject private var gridService: StickerGridService
    init(viewModel: SitckerCollectionViewModel, gridService: StickerGridService = .shared) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._gridService = ObservedObject(wrappedValue: gridService)
    }
    
    var body: some View {
        VStack {
            CustomNavigationBar(leadingType: .back(action: { coordinator.pop() }), centerType: .title(title: "스티커 만들기"), trailingType: .none, navigationColor: .black)
                .padding(.horizontal, 20)
            
            categoryTabs
                .padding(.vertical, 16)
            
            StickerGrid(
                items: gridService.stickerItems(for: gridService.selectedCategory),
                remoteURLByItemID: gridService.stickerImageURLs,
                loadingItemIDs: gridService.loadingItemIDs,
                columns: columns,
                rowSpacing: 26,
                onItemAppear: { id in
                    guard gridService.stickerImageURLs[id] == nil, gridService.loadingItemIDs.contains(id) == false, let item = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == id }) else { return }
                    
                    Task {
                        await gridService.fetchStickerImage(for: item, in: gridService.selectedCategory)
                    }
                },
                onItemTap: { item in
                    guard let tapped = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == item.id }) else { return }
                    
                    if viewModel.targetItemID == tapped.id {
                        // 이미 선택된 스티커를 다시 선택한 경우 → 선택 해제
                        viewModel.targetItemID = nil
                        StickerEmotionTagManager.shared.emotionTags = []
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.showMakeStickerButton = false
                        }
                    } else {
                        // 새 스티커 선택
                        viewModel.targetItemID = tapped.id
                        StickerEmotionTagManager.shared.emotionTags = [gridService.selectedCategory.rawValue, tapped.title]
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.showMakeStickerButton = true
                        }
                    }
                },
                selectedItemID: viewModel.targetItemID
            )
            .padding(.vertical, 10)
            
            /// 뷰 하단 빈 곳을 탭하면 버튼 닫힘
            Rectangle()
                .fill(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if viewModel.showMakeStickerButton {
                            viewModel.showMakeStickerButton = false
                            viewModel.targetItemID = nil
                        }
                    }
                )
            
            if viewModel.showMakeStickerButton {
                makeStickerButton
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .backHiddenSwipeEnabled()
        .background(dismissBackdrop)
        .background(.ppWhite)
        .onAppear {
            viewModel.reloadStickerIfNeeded()
        }
    }
    
    private var makeStickerButton: some View {
        HStack {
            CustomButton(title: "내 게시물로 만들기", style: .secondary, isEnable: true, action: {
                guard
                    let id = viewModel.targetItemID,
                    let item = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == id })
                else { return }
                
                let keyword = item.title
                StickerEmotionTagManager.shared.emotionTags = [gridService.selectedCategory.rawValue, keyword]
                
                coordinator.push(.photoPicker)
            })
            
            Spacer()
                .frame(maxWidth: 16)
            
            CustomButton(
                title: (viewModel.targetItemID != nil && gridService.stickerImageURLs[viewModel.targetItemID!] != nil) ? "스티커 변경" : "스티커 만들기",
                style: .primary,
                isEnable: true,
                action: {
                guard
                    let id = viewModel.targetItemID,
                    let item = gridService.stickerItems(for: gridService.selectedCategory).first(where: { $0.id == id })
                else { return }
                
                let keyword = item.title
                StickerEmotionTagManager.shared.emotionTags = [gridService.selectedCategory.rawValue, keyword]
                
                coordinator.push(.camera)
            })
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
                VStack(spacing: 12) {
                    Text(category.rawValue)
                        .font(isSelected ? .subtitleSemiBold16 : .bodyRegular16)
                        .foregroundColor(isSelected ? Color.ppBlack : Color.ppGray300)
                    
                    ZStack {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.clear)
                        
                        if isSelected {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(Color.ppPrime)
                                .cornerRadius(5)
                                .matchedGeometryEffect(
                                    id: "categoryUnderline",
                                    in: categoryUnderlineNamespace
                                )
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        gridService.selectedCategory = category
                        viewModel.showMakeStickerButton = false
                        viewModel.targetItemID = nil
                    }
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
