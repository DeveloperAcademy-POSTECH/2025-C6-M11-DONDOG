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
    let isTopImage: Bool //zIndex로 위치 변환을 위한 변수
    let onStickerButtonTapped: (() -> Void)?
    let selectedStickerEmotion: String?
    let stickerImage: UIImage?  // 이 게시물에 붙은 스티커 이미지 (이미 테두리 적용됨)
    let isMyPost: Bool?  // 내 게시물인지 여부
    
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
                        if let caption = caption{
                            Text(caption)
                                .font(.subtitleMedium18)
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
                
                // 스티커 표시 영역
                if let isMyPost = isMyPost {
                    if let sticker = stickerImage, let emotion = selectedStickerEmotion {
                        
                        if !isMyPost {
                            // 다른 사람의 게시물: 클릭 가능한 버튼
                            Button {
                                onStickerButtonTapped?()
                            } label: {
                                Image(uiImage: sticker)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 120)
                                    .offset(x: 10, y: -10)
                            }
                        } else {
                            // 내 게시물: 스티커만 표시 (클릭 불가)
                            Image(uiImage: sticker)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 120)
                                .offset(x: 10, y: -10)
                        }
                    } else if !isMyPost {
                        // 스티커가 없고 다른 사람의 게시물: 스티커 버튼 표시
                        Button {
                            onStickerButtonTapped?()
                        } label: {
                            Image(systemName: "face.dashed")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(.ddSecondaryBlue)
                        }
                    } else {
                        // 내 게시물이고 스티커 없음
                        EmptyView()
                    }
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
    let onStickerButtonTapped: (() -> Void)?
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
                onStickerButtonTapped: nil,
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
                onStickerButtonTapped: onStickerButtonTapped,
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
        onStickerButtonTapped: nil,
        selectedStickerEmotion: "사랑해",
        stickerImage: UIImage(named: "stickerTest"),
        isMyPost: false  // Preview에서는 다른 사람 게시물로 설정
    )
})
