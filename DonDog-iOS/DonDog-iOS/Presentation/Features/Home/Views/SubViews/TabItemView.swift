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
    
    private var postImageType: PostImageType {
        tag == 0 ? .front : .back
    }
    
    private var stickers: Binding<[AttachedSticker]> {
        postImageType == .front ? $viewModel.frontStickers : $viewModel.backStickers
    }
    
    var body: some View {
        Group {
            switch imageSource {
            case .local(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                
            case .remote(let url):
                ZStack {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                    if isEditing {
                        Color.clear
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
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
        .blur(radius: DateUtils.isOver3daysSinceLastUpload() ? 12 : 0)
        .tag(tag)
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .ppBlack], startPoint: .top, endPoint: .bottom)
                .opacity(0.6)
                .frame(maxHeight: 97)
        }
        .overlay {
            if DateUtils.isOver3daysSinceLastUpload() {
                VStack(spacing: 6) {
                    Image("LockerIcon")
                    Text("사진을 업로드한 지 3일이 지나\n사진을 확인할 수 없어요")
                        .font(.subtitleSemiBold16)
                        .foregroundStyle(.ppWhite)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
        .task(id: postId) {
            if let postId = postId {
                viewModel.postId = postId
                viewModel.postImageType = postImageType
                await viewModel.fetchStickers()
            }
        }
        .onChange(of: viewModel.postImageType) { _, newType in
            if newType == postImageType {
                Task {
                    await viewModel.fetchStickers()
                }
            }
        }
    }
}
