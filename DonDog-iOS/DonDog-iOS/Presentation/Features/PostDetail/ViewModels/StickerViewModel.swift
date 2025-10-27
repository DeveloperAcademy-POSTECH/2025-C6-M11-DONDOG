//
//  StickerViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import Combine
import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit
import Kingfisher

final class StickerViewModel: ObservableObject {
    @Published var borderedStickers: [String: UIImage] = [:]
    @Published var emotions: [String: String] = [:]
    @Published var sticker: UIImage?
    
    private var roomId: String?
    private let db = Firestore.firestore()
    private let imageUtils = ImageUtils()
    private let stickerUtils = StickerUtils()
    
    func getStickerData(stickerPostId: String, stickerType: String) {
        getCurrentUserRoomId { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let roomId):
                self.roomId = roomId
                self.fetchStickerImage(roomId: roomId, stickerPostId: stickerPostId, stickerType: stickerType)
                
            case .failure(let error):
                print("roomId를 가져오지 못했습니다: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCurrentUserRoomId(completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        let uid = currentUser.uid
        
        db.collection("Users").document(uid).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document,
                  let roomId = document.get("roomId") as? String,
                  !roomId.isEmpty else {
                completion(.failure(FirebaseError.roomIdNotFound))
                return
            }
            
            completion(.success(roomId))
        }
    }
    
    private func fetchStickerImage(roomId: String, stickerPostId: String, stickerType: String) {
        let stickerPostRef = db.collection("Rooms")
            .document(roomId)
            .collection("posts")
            .document(stickerPostId)
        
        stickerPostRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("스티커 post 조회에 실패했습니다:", error.localizedDescription)
                return
            }
            
            guard
                let data = snapshot?.data(),
                let imageUrlString = data["frontImageURL"] as? String,
                let url = URL(string: imageUrlString)
            else {
                print("frontImageURL이 없거나 잘못되었습니다.")
                return
            }
            
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let value):
                    DispatchQueue.main.async {
                        let emotion = StickerUtils.EmotionType(rawValue: stickerType) ?? .none
                        let borderColor = emotion.borderColor
                        
                        DispatchQueue.global(qos: .userInitiated).async {
                            guard let stickerOnly = self.imageUtils.makeSticker(with: value.image) else {
                                print("스티커 생성에 실패했습니다")
                                return
                            }
                            
                            let resultImage = stickerOnly.addBorder(thickness: 50, color: borderColor) ?? stickerOnly
                            
                            DispatchQueue.main.async {
                                self.sticker = resultImage
                                self.borderedStickers[stickerPostId] = resultImage
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("Kingfisher 이미지 불러오기에 실패했습니다:", error.localizedDescription)
                }
            }
        }
    }
}

