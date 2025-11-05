//
//  StickerService.swift
//  DonDog-iOS
//
//  Created by 이서현 on 11/1/25.
//

import Foundation
import Kingfisher
import SwiftUI
import UIKit

final class StickerService {
    private let dataManager: DataManagerProtocol = DataManager.shared
    let connectUserInfo = UserPairingStore.shared
    
    func getStickerCollection(of postId: String) async -> [String: UIImage] {
        let stickerPostId = await getStickerPostId(of: postId) // 스티커 원본 이미지가 있는 postId 가져오기
        
        let stickerImage = await fetchStickerImage(of: stickerPostId) // 스티커 원본 이미지 가져오기
        
        let clippedImage = getClippedImage(of: stickerImage) // 누끼 따기
        
        let outlinedImages = getOutlinedImage(for: clippedImage) // 테두리 적용 후 [stickerType : 테두리 적용된 이미지] - outline: 테두리
        
        return getStickers(with: outlinedImages) // 데코까지 적용된 스티커 배열
    }
    
    private func getStickerPostId(of postId: String) async -> String {
        do {
            let currentUser: UserData = try await dataManager.fetch(path: "Users/\(connectUserInfo.myUid ?? "")")
            
            let post: PostData = try await dataManager.fetch(path: "Rooms/\(connectUserInfo.roomId ?? "")/posts/\(postId)")
            
            let stickerPostIdToFetch: String?
            if post.stickerPostId != nil && post.stickerPostId != "" {
                stickerPostIdToFetch = post.stickerPostId
            } else if let recentPostId = currentUser.recentPostId, !recentPostId.isEmpty {
                stickerPostIdToFetch = recentPostId
            } else {
                print("stickerPostId와 recentPostId 모두 없음")
                return ""
            }
            
            let postData: PostData = try await dataManager.fetch(path: "Rooms/\(connectUserInfo.roomId ?? "")/posts/\(stickerPostIdToFetch ?? "")")
            
            return postData.postId
        } catch {
            print("stickerPostId 가져오기 실패: \(error.localizedDescription)")
            return ""
        }
    }
    
    private func fetchStickerImage(of stickerPostId: String) async -> UIImage {
        do {
            let postData: PostData = try await dataManager.fetch(
                path: "Rooms/\(connectUserInfo.roomId ?? "")/posts/\(stickerPostId)"
            )
            guard let url = URL(string: postData.frontImageURL) else {
                print("스티커 이미지 URL 생성 실패")
                return UIImage()
            }

            let image = try await KingfisherManager.shared.retrieveImage(with: url).image
            
            return image
        } catch {
            print("스티커 이미지 가져오기 실패: \(error.localizedDescription)")
            return  UIImage()
        }
    }
    
    private func getClippedImage(of stickerImage: UIImage) -> UIImage {
        guard let mask = ImageUtils.makeMask(from: stickerImage) else {
            print("mask 생성 실패")
            return UIImage()
        }
        
        guard let baseImage = ImageUtils.applyingMask(to: stickerImage, with: mask) else {
            print("누끼 따기 실패")
            return UIImage()
        }
        
        guard let mask = ImageUtils.makeMask(from: baseImage) else { // 더 자연스럽게 하기 위해 2번 누끼 따기
            print("mask 생성 실패")
            return UIImage()
        }
        
        guard let clippedImage = ImageUtils.applyingMask(to: baseImage, with: mask) else {
            print("누끼 따기 실패")
            return UIImage()
        }
        
        return clippedImage
    }
    
    private func getOutlinedImage(for clippedImage: UIImage) -> [String: UIImage] {
        var outlinedImages: [String: UIImage] = [:]
        
        for stickerType in StickerType.allCases {
            let uiColor = UIColor(stickerType.outlineColor)
            
            if let outlinedImage = clippedImage.addOutline(thickness: 40, color: uiColor) {
                outlinedImages[stickerType.rawValue] = outlinedImage
            } else {
                print("이미지 합성 실패: \(stickerType.rawValue)")
                return [:]
            }
        }
        
        return outlinedImages
    }
    
    private func getStickers(with outlinedImages: [String: UIImage]) -> [String: UIImage] {
        var stickers: [String: UIImage] = [:]
        
        for stickerType in StickerType.allCases {
            let outlinedImage = outlinedImages[stickerType.rawValue] ?? UIImage()
            let decoImageName = stickerType.stickerDecoString
            
            let sticker: UIImage
            let outlinedSize = outlinedImage.size
            let decoWidth = outlinedSize.width * 1.27
            
            sticker = ImageUtils.renderViewAsImage(
                ZStack {
                    Image(uiImage: outlinedImage)
                    Image(decoImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: decoWidth)
                }
                    .offset(x: 16, y: -36),
                size: CGSize(width: decoWidth, height: outlinedSize.height)
            )
            
            stickers[stickerType.rawValue] = sticker
        }
        
        return stickers
    }
}
