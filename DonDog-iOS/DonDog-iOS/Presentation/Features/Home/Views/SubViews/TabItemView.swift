//
//  TabItemView.swift
//  DonDog-iOS
//
//  Created by Ito on 11/19/25.
//

import Kingfisher
import SwiftUI

enum HomeImageSource {
    case local(UIImage)
    case remote(URL)
}

struct TabItemView: View {
    @ObservedObject var viewModel: StickerViewModel
    @Binding var isEditing: Bool
    
    let imageSource: HomeImageSource
    let tag: Int
    let postId: String?
    var isShowGradient: Bool
    
    private var postImageType: PostImageType {
        tag == 0 ? .front : .back
    }
    
    private var stickers: Binding<[AttachedSticker]> {
        postImageType == .front ? $viewModel.frontStickers : $viewModel.backStickers
    }
    
    var body: some View {
        Group {
            switch imageSource {
            case .local:
                HStack {
                    Spacer()
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
                    Spacer()
                }
                .frame(maxHeight: 468)
                .background {
                    Color.ppGray200
                }
                
            case .remote(let url):
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
                                    .frame(maxHeight: 468)
                                    .frame(width: 353)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        }
                        .fade(duration: 0.25)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 468)
                    
                    if isEditing {
                        Color.clear
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
                            .onTapGesture {
                                isEditing = false
                                Task {
                                    await viewModel.saveStickers()
                                }
                                viewModel.selectedStickerID = nil
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in }
                            )
                    }
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
                        .zIndex(viewModel.selectedStickerID == sticker.id ? 1: 0)
                        .onTapGesture {
                            if isEditing {
                                viewModel.selectedStickerID = sticker.id
                            }
                        }
                    }
                }
                .frame(maxHeight: 468)
            }
        }
        .tag(tag)
        .overlay(alignment: .bottom) {
            if !isEditing {
                LinearGradient(colors: [.clear, .ppBlack], startPoint: .top, endPoint: .bottom)
                    .opacity(isShowGradient ? 0.6 : 0)
                    .frame(maxHeight: 97)
                    .frame(width: 353)
                    .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
        .task(id: postId) {
            if let postId = postId {
                if viewModel.postId != postId {
                    viewModel.frontStickers = []
                    viewModel.backStickers = []
                    viewModel.selectedStickerID = nil
                    
                    viewModel.postId = postId
                    await viewModel.fetchStickers()
                }
                viewModel.postImageType = postImageType
            }
        }
    }
}
