//
//  StickerView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import Kingfisher
import SwiftUI

struct StickerView: View {
    @Binding var sticker: AttachedSticker
    var isSelected: Bool
    var isEditable: Bool
    var onDelete: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Angle = .zero
    
    var body: some View {
        ZStack {
            KFImage(sticker.stickerURL)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .gesture(isEditable ? dragGesture.simultaneously(with: scaleGesture).simultaneously(with: rotationGesture) : nil)
                .overlay {
                    if isEditable && isSelected {
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(.ddWhite, lineWidth: 1)
                            .padding(-8)
                    }
                }
            
            if isEditable && isSelected {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.ddBlack)
                        .background(
                            Circle()
                                .fill(.ddWhite)
                                .frame(width: 18, height: 18)
                        )
                }
                .offset(x: -65, y: -65)
            }
        }
        .scaleEffect(sticker.scale)
        .rotationEffect(sticker.rotation)
        .offset(x: sticker.position.x, y: sticker.position.y)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                sticker.position = CGPoint(
                    x: lastOffset.width + value.translation.width,
                    y: lastOffset.height + value.translation.height
                )
            }
            .onEnded { value in
                lastOffset.width += value.translation.width
                lastOffset.height += value.translation.height
            }
    }
    
    private var scaleGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                sticker.scale = lastScale * value
            }
            .onEnded { _ in
                lastScale = sticker.scale
            }
    }
    
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                sticker.rotation = lastRotation + value
            }
            .onEnded { _ in
                lastRotation = sticker.rotation
            }
    }
    
    func cornerOffset(xSign: CGFloat, ySign: CGFloat) -> (CGFloat, CGFloat) {
        let halfSize = 65 * sticker.scale
        let radians = sticker.rotation.radians
        let x = xSign * halfSize * cos(radians) - ySign * halfSize * sin(radians)
        let y = xSign * halfSize * sin(radians) + ySign * halfSize * cos(radians)
        return (x, y)
    }
}
