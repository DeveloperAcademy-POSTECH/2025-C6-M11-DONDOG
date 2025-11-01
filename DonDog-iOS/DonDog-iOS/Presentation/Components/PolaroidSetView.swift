//
//  PolaroidFrame.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/15/25.
//

import SwiftUI
import Kingfisher

enum DisplayableImage {
    case url(URL)
    case uiImage(UIImage)
}

struct PolaroidFrame: View {
    let image: DisplayableImage
    let nickname: String
    let createdAt: String
    let caption: String?
    let isTopImage: Bool
    // onStickerButtonTapped 제거
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
        ZStack{
            VStack(spacing: 0) {
                Spacer()
                imageView(image)
                    .cornerRadius(3)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 1, y: 2)
                    .frame(width: 240, height: 320)
                HStack{
                    VStack(spacing: 0){
                        HStack{
                            if let caption = caption{
                                Text(caption)
                                    .font(.polaroidCaptionRegular20)
                                    .foregroundColor(.ddBlack)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 4)
                        
                        HStack(spacing: 4){
                            Text(nickname)
                                .font(.captionRegular11)
                                .foregroundColor(.ddGray500)
                            Text(createdAt)
                                .font(.captionRegular11)
                                .foregroundColor(.ddGray500)
                            Spacer()
                        }
                    }
                    Spacer()
                   if stickerImage == nil && nickname != "" {
                        Image(systemName: "circle.dashed")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.ddSecondaryBlue)
                            .frame(width: 36, height: 36)
                    }
                }
                .frame(width: 240, height: 79)
                .padding(.leading, 4)
                .background(.ddWhite)
            }
            .frame(width: 272, height: 415)
            .background(.ddWhite)
            .cornerRadius(6)
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 1, y: 2)
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    if let sticker = stickerImage, let _ = selectedStickerType {
                        ZStack{
                            Image(uiImage: sticker)
                                .resizable()
                                .frame(width: 110, height: 138)
                            Image(stickerDecoString)
                        }.offset(x: 16, y: -36)
                    }
                }.frame(width: 272, height: 63)
            }.frame(width: 272, height: 415)
            
        }
        
    }
}

struct PolaroidSetView: View {
    @State var isTopImage = true
    
    let frontImage: DisplayableImage
    let backImage: DisplayableImage
    let nickname: String
    let createdAt: String
    let caption: String?
    let selectedStickerType: String?
    let isMyPost: Bool  // 내 게시물인지 여부
    
    var body: some View {
        ZStack {
            PolaroidFrame(
                image: backImage,
                nickname: "",
                createdAt: "",
                caption: "",
                isTopImage: !isTopImage,
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
            .offset(x: -50 ,y: -57)
            
            PolaroidFrame(
                image: frontImage,
                nickname: nickname,
                createdAt: createdAt,
                caption: caption,
                isTopImage: isTopImage,
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

//#Preview(body: {
//    PolaroidSetView(
//        frontImage: UIImage(named: "test1")!,
//        backImage: UIImage(named: "test2")!,
//        nickname: "이토",
//        createdAt: "오전 04:45",
//        caption: "하이디라오 짱맛",
//        selectedStickerType: "사랑해",
//        stickerImage: UIImage(named: "frontTest")!,
//        isMyPost: false  // Preview에서는 다른 사람 게시물로 설정
//    )
//})
