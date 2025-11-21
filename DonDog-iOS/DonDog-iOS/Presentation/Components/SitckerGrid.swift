//
//  SitckerGrid.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import Kingfisher
import SwiftUI
import UIKit

struct StickerGrid: View {
    let showedAt: StickerGridPlace
    let columns: [GridItem]
    let rowSpacing: CGFloat
    
    let items: [StickerItem]
    let stickerImageURLs: [StickerItem.ID: URL]
    let loadingItemIDs: Set<StickerItem.ID>
    let selectedItemID: StickerItem.ID?
    let categoryKey: String?
    let role: String?

    var isStickerConfirmPresented: Binding<Bool>?
    let onItemAppear: (StickerItem.ID) -> Void
    let onItemTap: (StickerItem) -> Void
    let onPlusTap: (StickerItem) -> Void
    
    init(
        showedAt: StickerGridPlace,
        items: [StickerItem],
        remoteURLByItemID: [StickerItem.ID: URL],
        loadingItemIDs: Set<StickerItem.ID>,
        columns: [GridItem],
        rowSpacing: CGFloat = 24,
        isStickerConfirmPresented: Binding<Bool>? = nil,
        onItemAppear: @escaping (StickerItem.ID) -> Void,
        onItemTap: @escaping (StickerItem) -> Void,
        onPlusTap: ((StickerItem) -> Void)? = nil,
        selectedItemID: StickerItem.ID? = nil,
        categoryKey: String? = nil,
        role: String? = nil
    ) {
        self.showedAt = showedAt
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
        self.categoryKey = categoryKey
        self.role = role
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: rowSpacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack {
                    StickerCellView(
                        showedAt: showedAt,
                        title: item.title,
                        url: stickerImageURLs[item.id],
                        isLoading: loadingItemIDs.contains(item.id),
                        isSelected: item.id == selectedItemID,
                        hasSelection: selectedItemID != nil,
                        index: index,
                        categoryKey: categoryKey,
                        role: role,
                        onTapLoaded: { onItemTap(item) },
                        onTapEmpty: { onPlusTap(item) }
                    )
                }
                .contentShape(Rectangle())
                .task { onItemAppear(item.id) }
            }
        }
    }
}

struct StickerCellView: View {
    let showedAt: StickerGridPlace
    let title: String
    let url: URL?
    let isLoading: Bool
    let isSelected: Bool
    let hasSelection: Bool?
    let index: Int
    let categoryKey: String?
    let role: String?
    let onTapLoaded: () -> Void
    let onTapEmpty: () -> Void
    
    private func resolvedPlaceholderName() -> String? {
        guard let categoryKey else { return nil }
        
        let order = index + 1
        let stateSuffix: String
        if hasSelection == true {
            stateSuffix = isSelected ? "off" : "on"
        } else {
            stateSuffix = "on"
        }
        
        // 1) (배열)_(순서)_(role)_blank_on/off로 검색
        if let role, !role.isEmpty {
            let roleCandidate = "\(categoryKey)_\(order)_\(role)_blank_\(stateSuffix)"
            if UIImage(named: roleCandidate) != nil {
                return roleCandidate
            }
        }
        // 2) 역할 없는 경우: (배열)_(순서)_blank_on/off
        let baseCandidate = "\(categoryKey)_\(order)_blank_\(stateSuffix)"
        if UIImage(named: baseCandidate) != nil {
            return baseCandidate
        }
        // 3) 둘 다 없으면 nil 반환 → 기본 동그라미+플러스 UI 사용
        return nil
    }
    
    var body: some View {
        if let url {
            VStack(spacing: 4) {
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
                } else {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                        .opacity(hasSelection == true ? (isSelected ? 1.0 : 0.5) : 1.0)
                        .frame(width: 120, height: 100, alignment: .center)
                        .onTapGesture(perform: onTapLoaded)
                }
                
                Text(title)
                    .font(.polaroidCaptionRegular16)
                    .foregroundColor(showedAt == .sheet ? .ppGray200 : .ppBlack)
            }
        } else if isLoading {
            ZStack {
                ProgressView()
                    .tint(showedAt == .sheet ? .ppGray300 : Color.ppPrime)
                    .opacity(showedAt == .sheet ? 0.5 : 1.0)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal, 48)
                    .padding(.top, 28)
                    .padding(.bottom, 48)
            }
            .frame(width: 120, height: 100)
        } else {
            VStack(spacing: 4) {
                if let name = resolvedPlaceholderName() {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 100)
                } else {
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
                    .frame(width: 120, height: 100)
                }
                
                Text(title)
                    .font(.polaroidCaptionRegular16)
                    .foregroundColor(showedAt == .sheet ? .ppGray200 : .ppBlack)
            }
            .onTapGesture { if !isLoading { onTapEmpty() } }
        }
    }
}

enum StickerGridPlace {
    case sheet
    case collection
}
