//
//  StickerService.swift
//  DonDog-iOS
//
//  Created by 이서현 on 11/1/25.
//

import Foundation
import Kingfisher
import UIKit
import SwiftUI

final class StickerService {
    private let dataManager: DataManagerProtocol = DataManager.shared
    private let imageUtils = ImageUtils()
    private var roomId: String?
    private var stickerPostId: String?
    private var stickerImage: UIImage? // 스티커 원본 이미지
    private var clippedImage: UIImage? // 누끼 따진 이미지
    private var outlinedImages: [String : UIImage?] = [:] // [stickerType : 테두리 적용된 이미지] - outline: 테두리
    
    func getStickerCollection(of postId: String) async -> [String: UIImage] {
        await getStickerPostId(of: postId) // 스티커 원본 이미지가 있는 postId 가져오기
        
        guard let stickerPostId = stickerPostId else {
            print("스티커로 만들 게시물이 없습니다")
            return [:]
        }
        await fetchStickerImage(of: stickerPostId) // 스티커 원본 이미지 가져오기
        
        getClippedImage() // 누끼 따기
        
        getOutlinedImage() // 테두리 적용
        
        return getStickers() // 데코까지 적용된 스티커 배열
    }
    
    private func getStickerPostId(of postId: String) async {
        guard let currentUserId = dataManager.getCurrentUserId() else { return }

        do {
            let currentUser: UserData = try await dataManager.fetch(path: "Users/\(currentUserId)")
            guard let roomId = currentUser.roomId, !roomId.isEmpty else {
                print("getStickerPostId에서 roomId가 없음")
                return
            }
            self.roomId = roomId
            
            let post: PostData = try await dataManager.fetch(path: "Rooms/\(roomId)/posts/\(postId)")
            
            let stickerPostIdToFetch: String
            if !post.stickerPostId.isEmpty {
                stickerPostIdToFetch = post.stickerPostId
            } else if let recentPostId = currentUser.recentPostId, !recentPostId.isEmpty {
                stickerPostIdToFetch = recentPostId
            } else {
                print("stickerPostId와 recentPostId 모두 없음")
                return
            }
            
            let postData: PostData = try await dataManager.fetch(path: "Rooms/\(roomId)/posts/\(stickerPostIdToFetch)")
            stickerPostId = postData.postId
        } catch {
            print("stickerPostId 가져오기 실패: \(error.localizedDescription)")
        }
    }
    
    private func fetchStickerImage(of stickerPostId: String) async {
        guard let roomId = roomId else {
            print("fetchStickerImage에서 roomId가 없음")
            return
        }

        do {
            let postData: PostData = try await dataManager.fetch(
                path: "Rooms/\(roomId)/posts/\(stickerPostId)"
            )
            guard let url = URL(string: postData.frontImageURL) else {
                print("스티커 이미지 URL 생성 실패")
                return
            }

            let image = try await KingfisherManager.shared.retrieveImage(with: url).image
            await MainActor.run {
                self.stickerImage = image
            }
        } catch {
            print("스티커 이미지 가져오기 실패: \(error.localizedDescription)")
        }
    }
    
    private func getClippedImage() {
        guard let stickerImage = stickerImage else {
            print("스티커 원본 이미지 없음")
            return
        }
        
        guard let mask = imageUtils.makeMask(from: stickerImage) else {
            print("mask 생성 실패")
            return
        }
        
        guard let baseImage = imageUtils.applyingMask(to: stickerImage, with: mask) else {
            print("누끼 따기 실패")
            return
        }
        
        guard let mask = imageUtils.makeMask(from: baseImage) else { // 더 자연스럽게 하기 위해 2번 누끼 따기
            print("mask 생성 실패")
            return
        }
        
        clippedImage = imageUtils.applyingMask(to: baseImage, with: mask)
    }
    
    private func getOutlinedImage() {
        guard let clippedImage = clippedImage else {
            print("clippedImage 없음")
            return
        }
        
        for stickerType in StickerType.allCases {
            let uiColor = UIColor(stickerType.outlineColor)
            
            if let outlinedImage = clippedImage.addOutline(thickness: 40, color: uiColor) {
                outlinedImages[stickerType.rawValue] = outlinedImage
            } else {
                print("이미지 합성 실패: \(stickerType.rawValue)")
            }
        }
    }
    
    private func getStickers() -> [String: UIImage] {
        var stickers: [String: UIImage] = [:]
        
        for stickerType in StickerType.allCases {
            let outlinedImage = outlinedImages[stickerType.rawValue] ?? UIImage()
            let decoImageName = stickerType.stickerDecoString
            
            let sticker: UIImage
            if let outlinedImage {
                let outlinedSize = outlinedImage.size
                let decoWidth = outlinedSize.width * 1.27
                
                sticker = imageUtils.renderViewAsImage(
                    ZStack {
                        Image(uiImage: outlinedImage)
                        Image(decoImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: decoWidth)
                    }
                    .offset(x: 16, y: -36),
                    size: CGSize(width: decoWidth, height: outlinedSize.height)
                )
                
            } else {
                sticker = UIImage()
            }
            
            stickers[stickerType.rawValue] = sticker
        }
        
        return stickers
    }
}
