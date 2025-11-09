//
//  PostContentsViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 11/7/25.
//

import Combine
import CoreGraphics
import Foundation
import SwiftUI

final class PostContentsViewModel: ObservableObject {
    @Published var stickers: [AttachedSticker] = []
    @Published var selectedStickerID: UUID?
    @State private var isEditing = true
    let baseImage: String = ""
    
    func addSticker(named imageName: String) {
        let newSticker = AttachedSticker(
            imageName: imageName,
            position: .zero,
            scale: 1.0,
            rotation: .zero
        )
        stickers.append(newSticker)
        selectedStickerID = newSticker.id
    }
    
    func removeSticker(_ sticker: AttachedSticker) {
        stickers.removeAll { $0.id == sticker.id }
    }
    
    func saveStickers() {
        // print()로 상태 출력
        print("===== StickerData 상태 =====")
        for s in stickers {
            print("ID: \(s.id)")
            print("Image: \(s.imageName)")
            print("Position: \(s.position)")
            print("Scale: \(s.scale)")
            print("Rotation: \(s.rotation.degrees)°")
            print("---------------------------")
        }
        print("============================\n")
        
        if let encoded = try? JSONEncoder().encode(stickers) {
            UserDefaults.standard.set(encoded, forKey: "savedStickers")
        }
    }
    
    func loadSavedStickers() {
        if let data = UserDefaults.standard.data(forKey: "savedStickers"),
           let decoded = try? JSONDecoder().decode([AttachedSticker].self, from: data) {
            stickers = decoded
        }
    }

}
