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
    @Binding var isZooming: Bool  // @Environment 대신 Binding 사용
    @Binding var isShowDetail: Bool
    @State private var loadFailed: Bool = false
    let isFront: Bool
    
    private var url: URL? {
        URL(string: urlString)
    }
    
    private var stickers: Binding<[AttachedSticker]> {
            isFront ? $viewModel.frontStickers : $viewModel.backStickers
        }
    
    var body: some View {
        ZStack {
            KFImage(url)
                .placeholder {
                    HStack {
                        VStack {
                            Spacer()
                            Image("LoadingView")
                            Text("지금 사진을 불러오는 중이에요.")
                                .font(.subtitleSemiBold16)
                                .foregroundStyle(.ppGray700)
                            Text("곧 사진이 도착해요! 잠시만 기다려 주세요.")
                                .font(.captionRegular14)
                                .foregroundStyle(.ppGray500)
                                .padding(.top, 2)
                            Spacer()
                        }
                    }
                    .frame(maxHeight: 468)
                    .frame(width: 353)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .background {
                        Color.ppGray200
                    }
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
            
            if !isShowDetail {
                ForEach(stickers) { $sticker in
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
}
