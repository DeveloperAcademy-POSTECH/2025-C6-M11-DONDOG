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
    
    // @Published var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    
    @Published var frontStickers: [AttachedSticker] = []
    @Published var backStickers: [AttachedSticker] = []
    @Published var selectedStickerID: UUID?
    
    @Published var shouldReopenSheetAfterCamera: Bool = false
    @Published var targetItemID: StickerItem.ID?
    @Published var previewURL: URL?
    
    @Published var isStickerAttached: Bool = false
    @MainActor
    @Published var isSaving = false
    
    let dataManager: DataManagerProtocol = DataManager.shared
    let connectUserInfo = UserPairingStore.shared
    var roomId: String = ""
    
    private var offsetIndex = [0, 0]
    
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
            await self.fetchStickers()
        }
    }
    
    func addSticker(with url: URL) {
        if postImageType == .front {
            if frontStickers.count < 24 {
                let newSticker = AttachedSticker(
                    createdAt: Date.now,
                    stickerURL: url,
                    postImageType: postImageType.rawValue,
                    position: orderedPosition(),
                    scale: 1.0,
                    rotation: .zero
                )
                
                frontStickers.append(newSticker)
                selectedStickerID = newSticker.id
            }
        } else {
            if backStickers.count < 24 {
                let newSticker = AttachedSticker(
                    createdAt: Date.now,
                    stickerURL: url,
                    postImageType: postImageType.rawValue,
                    position: orderedPosition(),
                    scale: 1.0,
                    rotation: .zero
                )
                
                backStickers.append(newSticker)
                selectedStickerID = newSticker.id
            }
        }
        //selectedStickerID = newSticker.id
        isStickerAttached = true
    }
    
    private func orderedPosition() -> CGPoint {
        let x = [ -97, 97 ]
        let y = [ -161, -41, 79 ]
        
        let xIndex = offsetIndex[0] % 2
        let yIndex = offsetIndex[1] % 3
        let position = CGPoint(x: x[xIndex], y: y[yIndex])
        
        offsetIndex[0] += 1
        if xIndex != 0 {
            offsetIndex[1] += 1
        }
        
        return position
    }
    
    func removeSticker(_ sticker: AttachedSticker) async {
        if postImageType == .front {
            frontStickers.removeAll { $0.id == sticker.id }
        } else {
            backStickers.removeAll { $0.id == sticker.id }
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
        if isSaving { return }
        isSaving = true
        
        defer { isSaving = false }
        
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
        
        let postData: [String: Any] = [
            "stickerUpdatedAt": Date.now
        ]
        
        do {
            try await dataManager.batchUpdate([
                .update(
                    path: "Rooms/\(roomId)/posts/\(postId)",
                    data: postData
                )
            ])
        } catch {
            print("stickerUdpatedAt 최신화 실패: \(error.localizedDescription)")
        }
        isStickerAttached = false
    }
}
