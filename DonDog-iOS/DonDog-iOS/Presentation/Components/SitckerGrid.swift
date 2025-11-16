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
        onPlusTap: ((StickerItem) -> Void)? = nil
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
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: rowSpacing) {
            ForEach(items) { item in
                VStack {
                    StickerCellView(
                        title: item.title,
                        url: stickerImageURLs[item.id],
                        isLoading: loadingItemIDs.contains(item.id),
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
    let onTapLoaded: () -> Void
    let onTapEmpty: () -> Void
    
    var body: some View {
        if let url {
            ZStack {
                KFImage(url)
                    .resizable()
                    .scaledToFit()
                    .onTapGesture(perform: onTapLoaded)
                    .padding(.horizontal, 6)
                    .contentShape(Rectangle())
                    .frame(width: 105, height: 125)
                
                if isLoading {
                    ProgressView()
                        .tint(Color.ppPrime)
                        .frame(width: 24, height: 24)
                        .padding(.vertical, 50)
                }
            }
        } else if isLoading {
            ProgressView()
                .tint(Color.ppPrime)
                .frame(width: 24, height: 24)
                .padding(.vertical, 50)
        } else {
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .stroke(Color.ppGray300, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [10, 15]))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.ppGray300)
                    
                }
                .contentShape(Rectangle())
                
                Text(title)
                    .font(.polaroidCaptionRegular20)
                    .lineLimit(1)
            }
            .onTapGesture { if !isLoading { onTapEmpty() } }
        }
    }
}
