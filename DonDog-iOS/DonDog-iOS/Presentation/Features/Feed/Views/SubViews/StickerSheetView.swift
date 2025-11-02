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
    @State private var selectedType: StickerType?
    
    let initialSelectedType: StickerType?
    let stickers: [String: UIImage]
    let name: String
    let onSelect: (StickerType?) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 4){
                Text("\(name) 님의 셀카로")
                Text("스티커를 붙여보세요😉")
            }
            .font(.bodyRegular16)
            .foregroundColor(.ddGray600)
            .onAppear {
                selectedType = initialSelectedType
            }
            VStack(spacing: 8){
                HStack(spacing: 16) {
                    Spacer()
                    Button(action: { handleTap(.love) }) {
                        StickerContainerView(
                            sticker: stickers[StickerType.love.rawValue],
                            type: .love,
                            isSelected: selectedType == .love,
                            isOtherSelected: selectedType != nil && selectedType != .love
                        )
                    }
                    
                    Button(action: { handleTap(.cool) }) {
                        StickerContainerView(
                            sticker: stickers[StickerType.cool.rawValue],
                            type: .cool,
                            isSelected: selectedType == .cool,
                            isOtherSelected: selectedType != nil && selectedType != .cool
                        )
                    }
                    
                    Button(action: { handleTap(.what) }) {
                        StickerContainerView(
                            sticker: stickers[StickerType.what.rawValue],
                            type: .what,
                            isSelected: selectedType == .what,
                            isOtherSelected: selectedType != nil && selectedType != .what
                        )
                    }
                    Spacer()
                }
                HStack(spacing: 16) {
                    Spacer()
                    Button(action: { handleTap(.angry) }) {
                        StickerContainerView(
                            sticker: stickers[StickerType.angry.rawValue],
                            type: .angry,
                            isSelected: selectedType == .angry,
                            isOtherSelected: selectedType != nil && selectedType != .angry
                        )
                    }
                    
                    Button(action: { handleTap(.sad) }) {
                        StickerContainerView(
                            sticker: stickers[StickerType.sad.rawValue],
                            type: .sad,
                            isSelected: selectedType == .sad,
                            isOtherSelected: selectedType != nil && selectedType != .sad
                        )
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private func handleTap(_ type: StickerType) {
        if selectedType == type {
            selectedType = nil
            onSelect(nil)
        } else {
            selectedType = type
            onSelect(type)
        }
        dismiss()
    }
}

struct StickerContainerView: View {
    let sticker: UIImage?
    let type: StickerType
    let isSelected: Bool
    let isOtherSelected: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            if let sticker = sticker {
                Image(uiImage: sticker)
                    .resizable()
                    .frame(width: 105)
            } else {
                ProgressView()
            }
            
            ZStack{
                OutlinedText(
                    text: type.rawValue,
                    font: UIFont(name: FontName.sejongGeulggot.rawValue, size: 16) ?? UIFont.systemFont(ofSize: 16),
                    textColor: .ddBlack,
                    outlineColor: UIColor(type.outlineColor),
                    outlineWidth: 12
                )
                
                Text(type.rawValue)
                    .font(.polaroidCaptionRegular16)
                    .foregroundColor(.ddBlack)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 75, height: 18)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .opacity(isOtherSelected ? 0.3 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isOtherSelected)
    }
}
