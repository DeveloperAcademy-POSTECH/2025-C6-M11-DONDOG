//
//  StickerSheetView.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/16/25.
//

import SwiftUI
import UIKit

struct StickerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: String? = nil
    let stickerImage: UIImage?
    let currentSelectedType: String?
    let onStickerSelected: (String?) -> Void
    let borderedStickers: [String: UIImage]  // 미리 생성된 테두리 스티커들
    let nickname: String
    
    var body: some View {
        if stickerImage != nil {
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 4){
                    Text("\(nickname) 님의 셀카로")
                    Text("스티커를 붙여보세요😉")
                }
                .font(.bodyRegular16)
                    .foregroundColor(.ddGray600)
                    .onAppear {
                        selectedType = currentSelectedType
                    }
                VStack(spacing: 8){
                    HStack(spacing: 16) {
                        Spacer()
                        Button(action: {
                            let newType = selectedType == "사랑해" ? nil : "사랑해"
                            onStickerSelected(newType)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["사랑해"],
                                type: "사랑해",
                                isSelected: selectedType == "사랑해",
                                isOtherSelected: selectedType != nil && selectedType != "사랑해"
                            )
                        }
                        
                        Button(action: {
                            let newType = selectedType == "멋지다" ? nil : "멋지다"
                            onStickerSelected(newType)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["멋지다"],
                                type: "멋지다",
                                isSelected: selectedType == "멋지다",
                                isOtherSelected: selectedType != nil && selectedType != "멋지다"
                            )
                        }
                        
                        Button(action: {
                            let newType = selectedType == "뭐야?" ? nil : "뭐야?"
                            onStickerSelected(newType)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["뭐야?"],
                                type: "뭐야?",
                                isSelected: selectedType == "뭐야?",
                                isOtherSelected: selectedType != nil && selectedType != "뭐야?"
                            )
                        }
                        Spacer()
                    }
                    HStack(spacing: 16) {
                        Spacer()
                        Button(action: {
                            let newType = selectedType == "화나" ? nil : "화나"
                            onStickerSelected(newType)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["화나"],
                                type: "화나",
                                isSelected: selectedType == "화나",
                                isOtherSelected: selectedType != nil && selectedType != "화나"
                            )
                        }
                        
                        Button(action: {
                            let newType = selectedType == "슬퍼" ? nil : "슬퍼"
                            onStickerSelected(newType)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["슬퍼"],
                                type: "슬퍼",
                                isSelected: selectedType == "슬퍼",
                                isOtherSelected: selectedType != nil && selectedType != "슬퍼"
                            )
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

struct StickerContainerView: View {
    let borderedImage: UIImage?  // 미리 생성된 테두리 이미지
    let type: String
    let isSelected: Bool
    let isOtherSelected: Bool
    
    private var typeStrokeColor: Color {
            guard let stickerType = StickerType(rawValue: type) else {
                return .ddBlack
            }
            return stickerType.strokeColor
        }
    
    private var stickerDecoString: String {
            guard let stickerType = StickerType(rawValue: type) else {
                return ""
            }
            return stickerType.stickerDecoString
        }
    
    var body: some View {
        ZStack{
            VStack(spacing: 5) {
                if let borderedImage = borderedImage {
                    Image(uiImage: borderedImage)
                        .resizable()
                        .frame(width: 75, height: 95)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 69, height: 92)
                }
                
                ZStack{
                    StrokeTextView(text: type, textColor: .ddBlack, fontName: FontName.sejongGeulggot.rawValue, fontSize: 16, strokeColor: typeStrokeColor, strokeWidth: 12)
                    Text(type)
                        .font(.polaroidCaptionRegular16)
                        .foregroundColor(.ddBlack)
                        .fixedSize(horizontal: true, vertical: false)
                }.frame(width: 75, height: 18)
                    
            }
            Image(stickerDecoString)
                .resizable()
                .scaledToFit()
                .frame(width: 105, height: 110)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .opacity(isOtherSelected ? 0.3 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isOtherSelected)
    }
}

#Preview {
    StickerContainerView(borderedImage: UIImage(named: "frontTest")!, type: "멋지다", isSelected: false, isOtherSelected: false)
}

