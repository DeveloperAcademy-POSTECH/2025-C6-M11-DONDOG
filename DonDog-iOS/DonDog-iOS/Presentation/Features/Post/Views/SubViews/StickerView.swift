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
                
                Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
                    .foregroundColor(.ddWhite)
                    .background(
                        Circle()
                            .fill(.ddBlack)
                            .frame(width: 18, height: 18)
                    )
                    .offset(x: 65, y: 65)
                    .gesture(transformGesture)
            }
        }
        .scaleEffect(sticker.scale)
        .rotationEffect(sticker.rotation)
        .offset(x: sticker.position.x, y: sticker.position.y)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let newX = lastOffset.width + value.translation.width
                let newY = lastOffset.height + value.translation.height
                
                sticker.position = CGPoint(
                    x: min(max(newX, -150), 150),
                    y: min(max(newY, -200), 200)
                )
            }
            .onEnded { value in
                let finalX = lastOffset.width + value.translation.width
                let finalY = lastOffset.height + value.translation.height
                
                lastOffset.width = min(max(finalX, -150), 150)
                lastOffset.height = min(max(finalY, -200), 200)
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
    
    private var transformGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let center = CGPoint(x: 0, y: 0)
                
                let start = CGPoint(
                    x: value.startLocation.x - center.x,
                    y: value.startLocation.y - center.y
                )
                let end = CGPoint(
                    x: value.location.x - center.x,
                    y: value.location.y - center.y
                )
                
                let startDistance = hypot(start.x, start.y)
                let endDistance = hypot(end.x, end.y)
                let scaleDelta = endDistance / max(startDistance, 1)
                sticker.scale = lastScale * scaleDelta
                sticker.scale = max(0.4, min(sticker.scale, 3.0))
                
                let startAngle = atan2(start.y, start.x)
                let endAngle = atan2(end.y, end.x)
                let angleDelta = endAngle - startAngle
                sticker.rotation = lastRotation + Angle(radians: angleDelta)
            }
            .onEnded { _ in
                lastScale = sticker.scale
                lastRotation = sticker.rotation
            }
    }
}
