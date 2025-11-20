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
    var onInteraction: () -> Void
    
    @State private var localPosition: CGPoint = .zero
    @State private var isDragging = false
    
    @GestureState private var gestureScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    @State private var lastRotation: Double = .zero
    
    var body: some View {
        ZStack {
            KFImage(sticker.stickerURL)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 100)
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
                        .frame(width: 14, height: 16)
                        .foregroundColor(.ddBlack)
                        .background(
                            Circle()
                                .fill(.ddWhite)
                                .frame(width: 25, height: 25)
                        )
                }
                .offset(x: -65, y: -55)
                
                Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.ddWhite)
                    .background(
                        Circle()
                            .fill(.ddBlack)
                            .frame(width: 25, height: 25)
                    )
                    .offset(x: 65, y: 55)
                    .gesture(transformGesture)
            }
        }
        .onAppear {
            localPosition = sticker.position
        }
        .scaleEffect(sticker.scale * gestureScale)
        .rotationEffect(.degrees(sticker.rotation))
        .offset(x: sticker.position.x, y: sticker.position.y)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                onInteraction()
                isDragging = true
                
                let scaleFactor = max(sticker.scale, 0.1)
                let adjustedTranslation: CGSize
                if scaleFactor < 1.0 {
                    adjustedTranslation = CGSize(width: value.translation.width * scaleFactor, height: value.translation.height * scaleFactor)
                } else {
                    adjustedTranslation = CGSize(width: value.translation.width / scaleFactor, height: value.translation.height / scaleFactor)
                }
                
                let newX = sticker.position.x + adjustedTranslation.width
                let newY = sticker.position.y + adjustedTranslation.height
                
                localPosition = CGPoint(
                    x: min(max(newX, -150), 150),
                    y: min(max(newY, -200), 200)
                )
                sticker.position = localPosition
            }
            .onEnded { _ in
                isDragging = false
                sticker.position = localPosition
            }
    }

    private var scaleGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { currentState, gestureState, _ in
                let clamped = min(max(currentState, 0.5), 2.94)
                gestureState = clamped
            }
            .onChanged { _ in
                onInteraction()
            }
            .onEnded { value in
                let finalScale = sticker.scale * value
                sticker.scale = min(max(finalScale, 0.5), 2.94)
            }
    }
    
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                onInteraction()
                sticker.rotation = lastRotation + value.degrees
            }
            .onEnded { _ in
                lastRotation = sticker.rotation
            }
    }
    
    private var transformGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let center = CGPoint(x: sticker.position.x, y: sticker.position.y)
                
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
                sticker.scale = max(0.5, min(sticker.scale, 2.94))
                
                let startAngle = atan2(start.y, start.x)
                let endAngle = atan2(end.y, end.x)
                let angleDelta = endAngle - startAngle
                sticker.rotation = lastRotation + Angle(radians: angleDelta).degrees
            }
            .onEnded { _ in
                lastScale = sticker.scale
                lastRotation = sticker.rotation
            }
    }
}
