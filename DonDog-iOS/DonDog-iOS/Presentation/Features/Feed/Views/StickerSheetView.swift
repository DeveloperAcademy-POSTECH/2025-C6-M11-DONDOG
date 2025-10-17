//
//  StickerSheetView.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/16/25.
//

import SwiftUI

struct StickerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEmotion: String? = nil
    let stickerImage: UIImage?
    
    var body: some View {
        if let stickerImage = stickerImage {
            VStack(spacing: 24) {
                Spacer()
                Text("스티커를 붙여보세요")
                    .font(.bodyRegular16)
                    .foregroundColor(.ddGray600)
                VStack(spacing: 8){
                    HStack(spacing: 40) {
                        Spacer()
                        Button(action: {
                            selectedEmotion = selectedEmotion == "사랑해" ? nil : "사랑해"
                        }) {
                            StickerContainerView(
                                stickerImage: stickerImage,
                                emotion: "사랑해",
                                isSelected: selectedEmotion == "사랑해",
                                isOtherSelected: selectedEmotion != nil && selectedEmotion != "사랑해"
                            )
                        }

                        Button(action: {
                            selectedEmotion = selectedEmotion == "멋지다" ? nil : "멋지다"
                        }) {
                            StickerContainerView(
                                stickerImage: stickerImage,
                                emotion: "멋지다",
                                isSelected: selectedEmotion == "멋지다",
                                isOtherSelected: selectedEmotion != nil && selectedEmotion != "멋지다"
                            )
                        }
                        
                        Button(action: {
                            selectedEmotion = selectedEmotion == "뭐야?" ? nil : "뭐야?"
                        }) {
                            StickerContainerView(
                                stickerImage: stickerImage,
                                emotion: "뭐야?",
                                isSelected: selectedEmotion == "뭐야?",
                                isOtherSelected: selectedEmotion != nil && selectedEmotion != "뭐야?"
                            )
                        }
                        Spacer()
                    }
                    HStack(spacing: 40) {
                        Spacer()
                        Button(action: {
                            selectedEmotion = selectedEmotion == "화나" ? nil : "화나"
                        }) {
                            StickerContainerView(
                                stickerImage: stickerImage,
                                emotion: "화나",
                                isSelected: selectedEmotion == "화나",
                                isOtherSelected: selectedEmotion != nil && selectedEmotion != "화나"
                            )
                        }
                        
                        Button(action: {
                            selectedEmotion = selectedEmotion == "슬퍼" ? nil : "슬퍼"
                        }) {
                            StickerContainerView(
                                stickerImage: stickerImage,
                                emotion: "슬퍼",
                                isSelected: selectedEmotion == "슬퍼",
                                isOtherSelected: selectedEmotion != nil && selectedEmotion != "슬퍼"
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
    let stickerImage: UIImage
    let emotion: String
    let isSelected: Bool
    let isOtherSelected: Bool
    
    var borderColor: UIColor{
        switch emotion {
        case "사랑해":
            return .ddFeelingPink
        case "멋지다":
            return .ddFeelingYellow
        case "뭐야?":
            return .ddFeelingGreen
        case "화나":
            return .ddFeelingOrange
        case "슬퍼":
            return .ddFeelingBlue
        default:
            return .ddGray700
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: stickerImage.addBorder(thickness: 4, color: borderColor)!)
            Text(emotion)
                .font(.captionRegular11)
                .foregroundColor(.ddGray600)
                .fixedSize(horizontal: true, vertical: false)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .opacity(isOtherSelected ? 0.3 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isOtherSelected)
    }
}



#Preview {
    StickerSheetView(stickerImage: UIImage(named: "stickerTest")!)
}
