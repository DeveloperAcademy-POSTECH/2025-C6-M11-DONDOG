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
import Kingfisher

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
        guard !roomId.isEmpty else {
            assertionFailure("ArchiveStickerViewModel: roomId is empty")
            return
        }
        guard !postId.isEmpty else {
            assertionFailure("ArchiveStickerViewModel: postId is empty")
            return
        }
        guard !stickerPostId.isEmpty else {
            return
        }
        
        let stickerPostRef = db.collection("Rooms").document(roomId).collection("posts").document(stickerPostId)
        stickerPostRef.getDocument(source: .default) { [weak self] stickerSnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("스티커용 post 조회 실패:", error.localizedDescription)
                return
            }
            guard
                let stickerData = stickerSnapshot?.data(),
                let imageUrlString = stickerData["frontImageURL"] as? String
            else {
                print("스티커 frontImageURL 없음")
                return
            }
            
            let postRef = self.db.collection("Rooms").document(self.roomId).collection("posts").document(postId)
            postRef.getDocument(source: .default) { postSnapshot, postError in
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
                
                guard let url = URL(string: imageUrlString) else {
                    print("스티커 이미지 URL 변환 실패")
                    return
                }
                
                KingfisherManager.shared.retrieveImage(with: url) { result in
                    switch result {
                    case .success(let value):
                        let image = value.image
                        let utils = ImageUtils()
                        let borderColor = self.borderColor(for: emotion)
                        
                        DispatchQueue.global(qos: .userInitiated).async {
                            guard let stickerOnly = utils.makeSticker(with: image) else {
                                print("스티커 생성 실패")
                                return
                            }
                            
                            let resultImage = stickerOnly.addBorder(thickness: 50, color: borderColor) ?? stickerOnly
                            
                            DispatchQueue.main.async {
                                self.borderedStickers[postId] = resultImage
                                self.emotions[postId] = emotion
                            }
                        }
                        
                    case .failure(let error):
                        print("KF 스티커 이미지 불러오기 실패:", error.localizedDescription)
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
