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
    let currentSelectedEmotion: String?
    let onStickerSelected: (String?) -> Void
    let borderedStickers: [String: UIImage]  // 미리 생성된 테두리 스티커들
    
    var body: some View {
        if let stickerImage = stickerImage {
            VStack(spacing: 24) {
                Spacer()
                Text("스티커를 붙여보세요")
                    .font(.bodyRegular16)
                    .foregroundColor(.ddGray600)
                    .onAppear {
                        selectedEmotion = currentSelectedEmotion
                    }
                VStack(spacing: 8){
                    HStack(spacing: 40) {
                        Spacer()
                        Button(action: {
                            let newEmotion = selectedEmotion == "사랑해" ? nil : "사랑해"
                            onStickerSelected(newEmotion)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["사랑해"],
                                emotion: "사랑해",
                                isSelected: selectedEmotion == "사랑해",
                                isOtherSelected: selectedEmotion != nil && selectedEmotion != "사랑해"
                            )
                        }

                        Button(action: {
                            let newEmotion = selectedEmotion == "멋지다" ? nil : "멋지다"
                            onStickerSelected(newEmotion)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["멋지다"],
                                emotion: "멋지다",
                                isSelected: selectedEmotion == "멋지다",
                                isOtherSelected: selectedEmotion != nil && selectedEmotion != "멋지다"
                            )
                        }
                        
                        Button(action: {
                            let newEmotion = selectedEmotion == "뭐야?" ? nil : "뭐야?"
                            onStickerSelected(newEmotion)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["뭐야?"],
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
                            let newEmotion = selectedEmotion == "화나" ? nil : "화나"
                            onStickerSelected(newEmotion)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["화나"],
                                emotion: "화나",
                                isSelected: selectedEmotion == "화나",
                                isOtherSelected: selectedEmotion != nil && selectedEmotion != "화나"
                            )
                        }
                        
                        Button(action: {
                            let newEmotion = selectedEmotion == "슬퍼" ? nil : "슬퍼"
                            onStickerSelected(newEmotion)
                            dismiss()
                        }) {
                            StickerContainerView(
                                borderedImage: borderedStickers["슬퍼"],
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
    let borderedImage: UIImage?  // 미리 생성된 테두리 이미지
    let emotion: String
    let isSelected: Bool
    let isOtherSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            if let borderedImage = borderedImage {
                Image(uiImage: borderedImage)
                    .resizable()
                    .frame(width: 75, height: 100)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 75, height: 100)
            }
            
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
    StickerSheetView(
        stickerImage: UIImage(named: "stickerTest")!,
        currentSelectedEmotion: nil,
        onStickerSelected: { _ in },
        borderedStickers: [:]  // Preview에서는 빈 딕셔너리
    )
}
