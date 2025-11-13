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
        ZStack(alignment: .topTrailing) {
            KFImage(sticker.stickerURL)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .scaleEffect(sticker.scale)
                .rotationEffect(sticker.rotation)
                .offset(x: sticker.position.x, y: sticker.position.y)
                .gesture(isEditable ? dragGesture.simultaneously(with: scaleGesture).simultaneously(with: rotationGesture) : nil)
                .overlay {
                    if isEditable && isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                            .padding(-4)
                    }
                }
            
            if isEditable && isSelected {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .padding(4)
                }
                .offset(x: sticker.position.x + 60, y: sticker.position.y - 60)
            }
        }
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
}
