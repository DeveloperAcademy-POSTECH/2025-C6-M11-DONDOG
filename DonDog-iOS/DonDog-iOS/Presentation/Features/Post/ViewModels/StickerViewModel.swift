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
    var createdAt = Date()
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
    
    private let dataManager: DataManagerProtocol = DataManager.shared
    let connectUserInfo = UserPairingStore.shared
    var roomId: String = ""
    
    init() {
        guard let id = connectUserInfo.roomId else {
            print("roomId 가져오기 실패")
            return
        }
        self.roomId = id
    }
    
    func fetchStickers(postId: String) async {
        do {
            stickers = try await dataManager.fetchCollection(path: "Rooms/\(roomId)/posts/\(postId)/stickerAttachments")
            print(stickers)
        } catch {
            print("붙여진 스티커 로드 실패: \(error.localizedDescription)")
        }
    }
    
    func addSticker(with url: URL) {
        let newSticker = AttachedSticker(
            createdAt: Date.now,
            stickerURL: url,
            position: randomPosition(),
            scale: 1.0,
            rotation: .zero
        )
        stickers.append(newSticker)
        selectedStickerID = newSticker.id
    }
    
    private func randomPosition() -> CGPoint {
        let x: CGFloat = [ -122, 0, 122 ].randomElement()!
        let y: CGFloat = [ -125, 0, 125 ].randomElement()!
        return CGPoint(x: x, y: y)
    }
    
    func removeSticker(_ sticker: AttachedSticker) {
        stickers.removeAll { $0.id == sticker.id }
    }
    
    func saveStickers(postId: String) async {
        for sticker in stickers {
            let data: [String: Any] = [
                "id": sticker.id.uuidString,
                "createdAt": sticker.createdAt,
                "stickerURL": sticker.stickerURL.absoluteString,
                "position": [sticker.position.x, sticker.position.y],
                "scale": sticker.scale,
                "rotation": sticker.rotation.degrees
            ]
            
            do {
                try await dataManager.batchUpdate([
                    .upsert(
                        path: "Rooms/\(roomId)/posts/\(postId)/stickerAttachments/\(sticker.id.uuidString)",
                        data: data
                    )
                ])
            } catch {
                print("붙여진 스티커 저장 실패: \(error.localizedDescription)")
            }
        }
    }
}
