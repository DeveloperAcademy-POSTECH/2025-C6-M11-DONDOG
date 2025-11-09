//
//  SitckerGrid.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import Kingfisher
import SwiftUI

struct StickerGrid: View {
    let items: [StickerItem]
       let remoteURLByItemID: [StickerItem.ID: URL]
       let loadingItemIDs: Set<StickerItem.ID>
       let columns: [GridItem]
       @Binding var isCameraPresented: Bool
       var isStickerConfirmPresented: Binding<Bool>?
       let onItemAppear: (StickerItem.ID) -> Void
       let onItemTap: (StickerItem) -> Void
       let onPlusTap: (StickerItem) -> Void
       let onCameraDismiss: (StickerItem.ID) -> Void
       let onConfirmDismiss: ((StickerItem.ID) -> Void)?

       init(
           items: [StickerItem],
           remoteURLByItemID: [StickerItem.ID: URL],
           loadingItemIDs: Set<StickerItem.ID>,
           columns: [GridItem],
           isCameraPresented: Binding<Bool>,
           isStickerConfirmPresented: Binding<Bool>? = nil,
           onItemAppear: @escaping (StickerItem.ID) -> Void,
           onItemTap: @escaping (StickerItem) -> Void,
           onPlusTap: ((StickerItem) -> Void)? = nil,
           onCameraDismiss: @escaping (StickerItem.ID) -> Void,
           onConfirmDismiss: ((StickerItem.ID) -> Void)? = nil
       ) {
           self.items = items
           self.remoteURLByItemID = remoteURLByItemID
           self.loadingItemIDs = loadingItemIDs
           self.columns = columns
           self._isCameraPresented = isCameraPresented
           self.isStickerConfirmPresented = isStickerConfirmPresented
           self.onItemAppear = onItemAppear
           self.onItemTap = onItemTap
           self.onPlusTap = onPlusTap ?? onItemTap
           self.onCameraDismiss = onCameraDismiss
           self.onConfirmDismiss = onConfirmDismiss
       }


    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(items) { item in
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.06))
                            .frame(height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                            )

                        if let url = remoteURLByItemID[item.id] {
                            KFImage(url)
                                .resizable()
                                .scaledToFit()
                                .padding(12)
                                .contentShape(Rectangle())
                                .onTapGesture { onItemTap(item) }
                        } else {
                            if loadingItemIDs.contains(item.id) {
                                EmptyView()
                            } else {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 28, weight: .semibold))
                                    .contentShape(Rectangle())
                                    .onTapGesture { onPlusTap(item) }
                            }
                        }
                    }
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .task { onItemAppear(item.id) }
                .onChange(of: isCameraPresented) { _, presented in
                    if presented == false { onCameraDismiss(item.id) }
                }
                .background(
                    Group {
                        if let confirm = isStickerConfirmPresented, let onConfirmDismiss {
                            Color.clear.onChange(of: confirm.wrappedValue) { _, presented in
                                if presented == false { onConfirmDismiss(item.id) }
                            }
                        } else {
                            Color.clear
                        }
                    }
                )
            }
        }
    }
}
