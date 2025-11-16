//
//  StickerViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 11/7/25.
//

import Combine
import CoreGraphics
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct AttachedSticker: Identifiable, Codable {
    var id = UUID()
    var stickerURL: URL
    var position: CGPoint
    var scale: CGFloat
    var rotation: Angle
}

final class StickerViewModel: ObservableObject {
    @Published var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    
    @Published var stickers: [AttachedSticker] = []
    @Published var selectedStickerID: UUID?
    
    @Published var showCamera = false
    @Published var targetItemID: StickerItem.ID?
    @Published var previewURL: URL?
    
    func addSticker(with url: URL) {
        let newSticker = AttachedSticker(
            stickerURL: url,
            position: .zero,
            scale: 1.0,
            rotation: .zero
        )
        stickers.append(newSticker)
        selectedStickerID = newSticker.id
        print("stickers: \(stickers)")
    }
    
    func removeSticker(_ sticker: AttachedSticker) {
        stickers.removeAll { $0.id == sticker.id }
    }
    
    func saveStickers() {
        // print()로 상태 출력
        print("===== StickerData 상태 =====")
        for sticker in stickers {
            print("ID: \(sticker.id)")
            print("ImageURL: \(sticker.stickerURL)")
            print("Position: \(sticker.position)")
            print("Scale: \(sticker.scale)")
            print("Rotation: \(sticker.rotation.degrees)°")
            print("---------------------------")
        }
        print("============================\n")
        
        if let encoded = try? JSONEncoder().encode(stickers) {
            UserDefaults.standard.set(encoded, forKey: "savedStickers")
        }
    }
}
