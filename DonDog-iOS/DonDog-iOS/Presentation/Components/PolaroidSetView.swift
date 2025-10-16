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
    let isTopImage: Bool //zIndex로 위치 변환을 위한 변수
    
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
                        Text(caption)
                            .font(.subtitleMedium18)
                            .foregroundColor(.ddBlack)
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
                if caption != ""{
                    Button{
                        //스티커 로직
                    }label: {
                        Image(systemName: "face.dashed")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.ddSecondaryBlue)
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
    let caption: String
    
    var body: some View {
        ZStack {
            PolaroidFrame(image: backImage, nickname: "", createdAt: "", caption: "", isTopImage: !isTopImage)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isTopImage.toggle()
                    }
                }
                .zIndex(isTopImage ? 0 : 1)
                .rotationEffect(.degrees(8))
                .offset(x: -50 ,y: -57)
            
            PolaroidFrame(image: frontImage, nickname: nickname, createdAt: createdAt, caption: caption, isTopImage: isTopImage)
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
    PolaroidSetView(frontImage: UIImage(named: "test1")!, backImage: UIImage(named: "test2")!, nickname: "이토", createdAt: "오전 04:45", caption: "하이디라오 짱맛")
})
