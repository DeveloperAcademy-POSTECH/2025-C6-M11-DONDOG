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
    
    @StateObject var viewModel = StickerViewModel()
    @State private var loadFailed: Bool = false

    private var url: URL? {
        URL(string: urlString)
    }

    var body: some View {
        ZStack {
            KFImage(url)
                .placeholder {
                    RoundedRectangle(cornerRadius: 15)
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
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.ddGray500)
                            .overlay(Image(systemName: "photo"))
                    }
                }
            
            ForEach($viewModel.stickers) { $sticker in
                StickerView(
                    sticker: $sticker,
                    isSelected: viewModel.selectedStickerID == sticker.id,
                    isEditable: isEditing,
                    onDelete: { viewModel.removeSticker(sticker) }
                )
                .onTapGesture {
                    if isEditing {
                        viewModel.selectedStickerID = sticker.id
                    }
                }
            }
        }
    }
}
