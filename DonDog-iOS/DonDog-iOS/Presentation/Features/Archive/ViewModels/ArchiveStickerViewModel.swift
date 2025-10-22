//
//  ArchiveStickerViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/20/25.
//

import Combine
import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

final class ArchiveStickerViewModel: ObservableObject {
    let roomId: String
    
    @Published var borderedStickers: [String: UIImage] = [:]
    @Published var emotions: [String: String] = [:]
    
    @Published var sticker: UIImage?
    
    private let db = Firestore.firestore()
    private let imageUtils = ImageUtils()
    private var mask: UIImage?
    
    init(roomId: String) {
        self.roomId = roomId
    }
    
    func getStickerData(stickerPostId: String, for postId: String) {
        let trimmed = stickerPostId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.lowercased() != "null" else { return }
        
        let stickerPostRef = db.collection("Rooms").document(roomId).collection("posts").document(trimmed)
        stickerPostRef.getDocument { [weak self] stickerSnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("스티커용 post 조회 실패:", error.localizedDescription)
                return
            }
            guard
                let stickerData = stickerSnapshot?.data(),
                let imageUrlString = stickerData["frontImageURL"] as? String
            else {
                print("스티커 frontImageURL 없음 for stickerPostId \(trimmed)")
                return
            }
            
            let postRef = self.db.collection("Rooms").document(self.roomId).collection("posts").document(postId)
            postRef.getDocument { postSnapshot, postError in
                if let postError = postError {
                    print("현재 postId \(postId) 조회 실패:", postError.localizedDescription)
                    return
                }
                guard
                    let postData = postSnapshot?.data(),
                    let emotion = postData["stickerType"] as? String
                else {
                    print("현재 postId \(postId)에 유효한 stickerType 없음")
                    return
                }
                
                PhotoSaveService.shared.downloadImage(from: imageUrlString) { result in
                    switch result {
                    case .success(let image):
                        DispatchQueue.global(qos: .userInitiated).async {
                            guard let stickerOnly = self.imageUtils.makeSticker(with: image) else {
                                print("스티커 생성 실패")
                                return
                            }
                            
                            let borderedSticker = stickerOnly.addBorder(
                                thickness: 50,
                                color: self.borderColor(for: emotion)
                            )
                            DispatchQueue.main.async {
                                self.borderedStickers[postId] = borderedSticker
                                self.emotions[postId] = emotion
                            }
                        }
                    case .failure(let error):
                        print("스티커 이미지 다운로드 실패:", error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func borderColor(for emotion: String) -> UIColor {
        switch emotion {
        case "사랑해":
            return .ddFeelingPink
        case "멋지다":
            return .ddFeelingYellow
        case "뭐야?":
            return .ddFeelingGreen
        case "화나":
            return .ddFeelingOrange
        case "슬퍼":
            return .ddFeelingBlue
        default:
            return .ddGray700
        }
    }
    
}
