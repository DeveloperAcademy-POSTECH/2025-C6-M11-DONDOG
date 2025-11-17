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
    var postImageType: String
    var position: CGPoint
    var scale: CGFloat
    var rotation: Double
}

enum PostImageType: String {
    case front = "frontImage"
    case back = "backImage"
}

final class StickerViewModel: ObservableObject {
    @Published var postId = ""
    @Published var postImageType: PostImageType = .front
    
    @Published var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    
    @Published var frontStickers: [AttachedSticker] = []
    @Published var backStickers: [AttachedSticker] = []
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
    
    func fetchStickers() async {
        do {
            frontStickers = try await dataManager.fetchWhereEqual(path: "Rooms/\(roomId)/posts/\(postId)/stickerAttachments", field: "postImageType", isEqualTo: PostImageType.front.rawValue)
            backStickers = try await dataManager.fetchWhereEqual(path: "Rooms/\(roomId)/posts/\(postId)/stickerAttachments", field: "postImageType", isEqualTo: PostImageType.back.rawValue)
        } catch {
            print("붙여진 스티커 로드 실패: \(error.localizedDescription)")
        }
    }
    
    func addSticker(with url: URL) {
        let newSticker = AttachedSticker(
            createdAt: Date.now,
            stickerURL: url,
            postImageType: postImageType.rawValue,
            position: randomPosition(),
            scale: 1.0,
            rotation: .zero
        )
        if postImageType == .front {
            frontStickers.append(newSticker)
        } else {
            backStickers.append(newSticker)
        }
        selectedStickerID = newSticker.id
    }
    
    private func randomPosition() -> CGPoint {
        let x: CGFloat = [ -122, 0, 122 ].randomElement()!
        let y: CGFloat = [ -125, 0, 125 ].randomElement()!
        return CGPoint(x: x, y: y)
    }
    
    func removeSticker(_ sticker: AttachedSticker) async {
        var targetArray = (sticker.postImageType == PostImageType.front.rawValue) ? frontStickers : backStickers
        
        if let index = targetArray.firstIndex(where: { $0.id == sticker.id }) {
            targetArray.remove(at: index)
        }

        do {
            try await dataManager.delete(
                path: "Rooms/\(roomId)/posts/\(postId)/stickerAttachments/\(sticker.id.uuidString)"
            )
        } catch {
            print("붙여진 스티커 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    func saveStickers() async {
        for sticker in postImageType == .front ? frontStickers : backStickers {
            let data: [String: Any] = [
                "id": sticker.id.uuidString,
                "createdAt": sticker.createdAt,
                "stickerURL": sticker.stickerURL.absoluteString,
                "postImageType": postImageType.rawValue,
                "position": [sticker.position.x, sticker.position.y],
                "scale": sticker.scale,
                "rotation": sticker.rotation
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
