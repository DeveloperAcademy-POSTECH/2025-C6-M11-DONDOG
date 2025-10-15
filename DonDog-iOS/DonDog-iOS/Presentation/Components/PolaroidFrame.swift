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
                    Text(nickname)
                        .font(.captionRegular11)
                        .foregroundColor(.ddGray500)
                        .padding(.leading, 4)
                    Text("\(DataUtils.formatDate(.now, format: "hh:mm"))")
                        .font(.captionRegular11)
                        .foregroundColor(.ddGray500)
                        .padding(.leading, 4)
                    Spacer()
                }.frame(width: 230)
                    .padding(.bottom, 16)
            }
            .frame(height: 63)
            .background(.ddWhite)
        }
        .background(.ddWhite)
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 1, y: 2)
    }
    
}

struct PolaroidSetView: View {
    @State var isTopImage = true
    
    let frontImage: UIImage = UIImage(named: "test1")!
    let backImage: UIImage = UIImage(named: "test2")!
    let nickname: String = "자고싶다"
    let createdAt: String = ""
    
    var body: some View {
        ZStack{
            PolaroidFrame(image: backImage, nickname: "뒷장", createdAt: createdAt, isFlipped: isTopImage)
                .onTapGesture {
                    isTopImage.toggle()
                }
                .zIndex(isTopImage ? 0 : 1)
            
            PolaroidFrame(image: frontImage, nickname: nickname, createdAt: createdAt, isFlipped: !isTopImage)
                .onTapGesture {
                    isTopImage.toggle()
                }
                .zIndex(isTopImage ? 1 : 0)
        }
    }
}

#Preview {
    PolaroidSetView()
}
