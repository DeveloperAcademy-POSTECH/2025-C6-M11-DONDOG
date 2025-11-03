//
//  PolaroidFrame.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/15/25.
//

import Kingfisher
import SwiftUI

enum DisplayableImage {
    case url(URL)
    case uiImage(UIImage)
}

struct PolaroidFrame: View {
    let image: DisplayableImage
    let name: String
    let createdAt: String
    let caption: String?
    let isTopImage: Bool
    // onStickerButtonTapped 제거
    let sticker: UIImage
    let selectedStickerType: String?
    let isMyPost: Bool?
    
    @ViewBuilder
    private func imageView(_ source: DisplayableImage) -> some View {
        switch source {
        case .url(let url):
            KFImage(url)
                .resizable()
                .scaledToFit()
        case .uiImage(let img):
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
        }
    }
    
    private var stickerDecoString: String {
        guard let stickerType = StickerType(rawValue: selectedStickerType ?? "") else {
            return ""
        }
        return stickerType.stickerDecoString
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                Spacer()
                imageView(image)
                    .cornerRadius(3)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 1, y: 2)
                    .frame(maxWidth: 240, maxHeight: 320)
                HStack {
                    VStack(spacing: 0) {
                        HStack {
                            if let caption = caption {
                                Text(caption)
                                    .font(.polaroidCaptionRegular20)
                                    .foregroundColor(.ddBlack)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 4)
                        
                        HStack(spacing: 4) {
                            Text(name)
                                .font(.captionRegular11)
                                .foregroundColor(.ddGray500)
                            Text(createdAt)
                                .font(.captionRegular11)
                                .foregroundColor(.ddGray500)
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    if selectedStickerType == nil && name != "" {
                        Image(systemName: "circle.dashed")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.ddSecondaryBlue)
                            .frame(width: 36, height: 36)
                    }
                }
                .frame(maxWidth: 240, maxHeight: 79)
                .padding(.leading, 4)
                .background(.ddWhite)
            }
            .frame(maxWidth: 272, maxHeight: 415)
            .background(.ddWhite)
            .cornerRadius(6)
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 1, y: 2)
            Image(uiImage: sticker)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 140, maxHeight: 145)
                .offset(x: 4)
        }
        .frame(maxWidth: 272, maxHeight: 415)
    }
}

struct PolaroidSetView: View {
    @State var isTopImage = true
    
    let frontImage: DisplayableImage
    let backImage: DisplayableImage
    let name: String
    let createdAt: String
    let caption: String?
    let stickers: [String: UIImage]?
    let selectedStickerType: String?
    let isMyPost: Bool  // 내 게시물인지 여부
    
    var body: some View {
        ZStack {
            PolaroidFrame(
                image: backImage,
                name: "",
                createdAt: "",
                caption: "",
                isTopImage: !isTopImage,
                sticker: UIImage(),
                selectedStickerType: nil,
                isMyPost: isMyPost
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTopImage.toggle()
                }
            }
            .zIndex(isTopImage ? 0 : 1)
            .rotationEffect(.degrees(8))
            .offset(x: -50, y: -57)
            
            PolaroidFrame(
                image: frontImage,
                name: name,
                createdAt: createdAt,
                caption: caption,
                isTopImage: isTopImage,
                sticker: stickers?[selectedStickerType ?? ""] ?? UIImage(),
                selectedStickerType: selectedStickerType,
                isMyPost: isMyPost
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTopImage.toggle()
                }
            }
            .zIndex(isTopImage ? 1 : 0)
        }
    }
}

#Preview {
    PolaroidSetView(frontImage: DisplayableImage.uiImage(UIImage()), backImage: DisplayableImage.uiImage(UIImage()), name: "", createdAt: "", caption: nil, stickers: nil, selectedStickerType: nil, isMyPost: false)
}
