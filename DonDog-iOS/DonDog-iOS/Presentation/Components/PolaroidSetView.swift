//
//  PolaroidFrame.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/15/25.
//

import SwiftUI

struct PolaroidFrame: View {
    let image: UIImage
    let nickname: String
    let createdAt: String
    let caption: String?
    let isTopImage: Bool
    // onStickerButtonTapped 제거
    let selectedStickerEmotion: String?
    let stickerImage: UIImage?
    let isMyPost: Bool?
    
    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(3)
                .frame(width: 230)
                .padding(16)
                .background(.ddWhite)
            HStack{
                VStack{
                    HStack{
                        if let caption = caption {
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
                
                // 스티커 표시 영역 - 이미지만 표시 (버튼 없음)
                if let sticker = stickerImage {
                    Image(uiImage: sticker)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 120)
                        .offset(x: 10, y: -10)
                }else if nickname != "" {
                    Image(systemName: "circle.dashed")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.ddSecondaryBlue)
                        .frame(width: 36, height: 36)
                }
            }
            .frame(width: 230, height: 63)
            .padding(.leading, 4)
            .padding(.bottom, 16)
            .background(.ddWhite)
        }
        .frame(width: 264, height: 415)
        .background(.ddWhite)
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 1, y: 2)
    }
}

struct PolaroidSetView: View {
    @State var isTopImage = true
    
    let frontImage: UIImage
    let backImage: UIImage
    let nickname: String
    let createdAt: String
    let caption: String?
    //let onStickerButtonTapped: (() -> Void)?
    let selectedStickerEmotion: String?
    let stickerImage: UIImage?  // 이 게시물에 붙은 스티커 이미지 (이미 테두리 적용됨)
    let isMyPost: Bool  // 내 게시물인지 여부
    
    var body: some View {
        ZStack {
            PolaroidFrame(
                image: backImage,
                nickname: "",
                createdAt: "",
                caption: "",
                isTopImage: !isTopImage,
                selectedStickerEmotion: nil,
                stickerImage: nil,
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
                selectedStickerEmotion: selectedStickerEmotion,
                stickerImage: stickerImage,
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

#Preview(body: {
    PolaroidSetView(
        frontImage: UIImage(named: "test1")!,
        backImage: UIImage(named: "test2")!,
        nickname: "이토",
        createdAt: "오전 04:45",
        caption: "하이디라오 짱맛",
        selectedStickerEmotion: "사랑해",
        stickerImage: UIImage(named: "stickerTest"),
        isMyPost: false  // Preview에서는 다른 사람 게시물로 설정
    )
})
