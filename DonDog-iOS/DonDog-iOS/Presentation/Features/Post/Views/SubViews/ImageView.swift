//
//  ImageView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 11/9/25.
//

import Kingfisher
import SwiftUI

struct ImageView: View {
    let urlString: String
    @Binding var isEditing: Bool
    
    @ObservedObject var viewModel: StickerViewModel
    @State private var loadFailed: Bool = false

    private var url: URL? {
        URL(string: urlString)
    }

    var body: some View {
        ZStack {
            KFImage(url)
                .placeholder {
                    Rectangle()
                        .fill(.ddGray500)
                }
                .onFailure { _ in
                    loadFailed = true
                }
                .cancelOnDisappear(true)
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
                .clipped()
                .overlay(alignment: .center) {
                    if loadFailed {
                        Rectangle()
                            .fill(.ddGray500)
                            .overlay(Image(systemName: "photo"))
                    }
                }
            
            ForEach(viewModel.postImageType == PostImageType.front ? $viewModel.frontStickers : $viewModel.backStickers) { $sticker in
                StickerView(
                    sticker: $sticker,
                    isSelected: viewModel.selectedStickerID == sticker.id,
                    isEditable: isEditing,
                    onDelete: {
                        Task {
                            await viewModel.removeSticker(sticker)
                        }
                    },
                    onInteraction: {
                        if isEditing {
                            viewModel.selectedStickerID = sticker.id
                        }
                    }
                )
                .onTapGesture {
                    if isEditing {
                        viewModel.selectedStickerID = sticker.id
                    }
                }
                .allowsHitTesting(isEditing)
            }
        }
    }
}
