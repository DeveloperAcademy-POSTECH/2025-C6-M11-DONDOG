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
    let caption: String
    let isFlipped: Bool //zIndex로 위치 변환을 위한 변수
    
    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(3)
                .frame(width: 230)
                .padding(16)
                .background(.ddWhite)
            VStack{
                Spacer()
                HStack{
                    Text(caption)
                        .font(.subtitleMedium18)
                        .foregroundColor(.ddBlack)
                    Spacer()
                }
                .frame(width: 230)
                .padding(.leading, 4)
                .padding(.bottom, 4)
                
                HStack(spacing: 4){
                    Text(nickname)
                        .font(.captionRegular11)
                        .foregroundColor(.ddGray500)
                    Text(createdAt)
                        .font(.captionRegular11)
                        .foregroundColor(.ddGray500)
                    Spacer()
                }.frame(width: 230)
                    .padding(.leading, 4)
                    .padding(.bottom, 16)
            }
            .frame(height: 63)
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
    let nickname: String = "자고싶다"
    let createdAt: String = DataUtils.formatDate(.now, format: "a hh:mm")
    
    var body: some View {
        ZStack {
            PolaroidFrame(image: backImage, nickname: "", createdAt: "", caption: "", isFlipped: isTopImage)
                .onTapGesture {
                    isTopImage.toggle()
                }
                .zIndex(isTopImage ? 0 : 1)
                .rotationEffect(.degrees(8))
                .offset(x: -50 ,y: -57)
            
            PolaroidFrame(image: frontImage, nickname: nickname, createdAt: createdAt, caption: "캡션 위치입니다", isFlipped: !isTopImage)
                .onTapGesture {
                    isTopImage.toggle()
                }
                .zIndex(isTopImage ? 1 : 0)
        }
    }
}

#Preview {
    PolaroidSetView(frontImage: UIImage(named: "test1")!, backImage: UIImage(named: "test2")!)
}
