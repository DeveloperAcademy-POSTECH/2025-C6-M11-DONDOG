//
//  SitckerGrid.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import Kingfisher
import SwiftUI

struct StickerGrid: View {
    let columns: [GridItem]
    let rowSpacing: CGFloat
    
    let items: [StickerItem]
    let stickerImageURLs: [StickerItem.ID: URL]
    let loadingItemIDs: Set<StickerItem.ID>
    let selectedItemID: StickerItem.ID?

    var isStickerConfirmPresented: Binding<Bool>?
    let onItemAppear: (StickerItem.ID) -> Void
    let onItemTap: (StickerItem) -> Void
    let onPlusTap: (StickerItem) -> Void
    
    init(
        items: [StickerItem],
        remoteURLByItemID: [StickerItem.ID: URL],
        loadingItemIDs: Set<StickerItem.ID>,
        columns: [GridItem],
        rowSpacing: CGFloat = 24,
        isStickerConfirmPresented: Binding<Bool>? = nil,
        onItemAppear: @escaping (StickerItem.ID) -> Void,
        onItemTap: @escaping (StickerItem) -> Void,
        onPlusTap: ((StickerItem) -> Void)? = nil,
        selectedItemID: StickerItem.ID? = nil
    ) {
        self.items = items
        self.stickerImageURLs = remoteURLByItemID
        self.loadingItemIDs = loadingItemIDs
        self.columns = columns
        self.rowSpacing = rowSpacing
        self.isStickerConfirmPresented = isStickerConfirmPresented
        self.onItemAppear = onItemAppear
        self.onItemTap = onItemTap
        self.onPlusTap = onPlusTap ?? onItemTap
        self.selectedItemID = selectedItemID
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: rowSpacing) {
            ForEach(items) { item in
                VStack {
                    StickerCellView(
                        title: item.title,
                        url: stickerImageURLs[item.id],
                        isLoading: loadingItemIDs.contains(item.id),
                        isSelected: item.id == selectedItemID,
                        hasSelection: selectedItemID != nil,
                        onTapLoaded: { onItemTap(item) },
                        onTapEmpty: { onPlusTap(item) },
                    )
                }
                .contentShape(Rectangle())
                .task { onItemAppear(item.id) }
            }
        }
    }
}

struct StickerCellView: View {
    let title: String
    let url: URL?
    let isLoading: Bool
    let isSelected: Bool
    let hasSelection: Bool
    let onTapLoaded: () -> Void
    let onTapEmpty: () -> Void
    
    var body: some View {
        if let url {
            ZStack {
                KFImage(url)
                    .resizable()
                    .scaledToFit()
                    .opacity(hasSelection ? (isSelected ? 1.0 : 0.5) : 1.0)
                    .frame(width: 120, height: 100, alignment: .center)
                    .onTapGesture(perform: onTapLoaded)
                
                if isLoading {
                    ZStack {
                        ProgressView()
                            .tint(Color.ppPrime)
                            .frame(width: 24, height: 24)
                            .padding(.horizontal, 48)
                            .padding(.top, 28)
                            .padding(.bottom, 48)
                    }
                    .frame(width: 120, height: 100)
                }
            }
            .frame(width: 120, height: 100)
        } else if isLoading {
            ZStack {
                ProgressView()
                    .tint(Color.ppPrime)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal, 48)
                    .padding(.top, 28)
                    .padding(.bottom, 48)
            }
            .frame(width: 120, height: 100)
        } else {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.ppGray600 : Color.ppGray300, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [7, 10]))
                        .frame(width: 60, height: 60)
                        .padding(.horizontal, 20)
                        .padding(10)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .ppGray600 : Color.ppGray300)
                    
                }
                .contentShape(Rectangle())
                
                Text(title)
                    .font(.polaroidCaptionRegular16)
            }
            .frame(width: 120, height: 100)
            .onTapGesture { if !isLoading { onTapEmpty() } }
        }
    }
}
