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
    
    /// 로컬 이미지로 스티커(누끼→보더→데코)를 생성해서 반환
    func makeSticker(from image: UIImage) async -> UIImage? {
        let tags = StickerEmotionTagManager.shared.emotionTags
        let title = tags[1]
        
        // 0) 입력 프리-리사이즈 (성능용, 최대 변 1024pt)
        let originalSize = image.size
        let preMaxEdgePt: CGFloat = 1024
        let preScale = min(preMaxEdgePt / max(originalSize.width, originalSize.height), 1)
        let preSize = CGSize(width: originalSize.width * preScale, height: originalSize.height * preScale)
        let preFormat = UIGraphicsImageRendererFormat.default()
        preFormat.scale = 1
        let preRenderer = UIGraphicsImageRenderer(size: preSize, format: preFormat)
        let resizedImage = preRenderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: preSize))
        }
        
        // 1) 누끼
        let clipped = getClippedImage(of: resizedImage)
        guard clipped.size.width >= 1, clipped.size.height >= 1 else { return nil }
        
        // 2) 스타일 해석 (StickerCategoryData에서 보더 색깔, 데코 이름 가져오기)
        guard let style = StickerStyleData.style(forTitle: title) else { return nil }
        
        // 2-1) 보더
        let uiColor = UIColor(style.outlineColor)
        guard let outlined = clipped.addOutline(thickness: 40, color: uiColor) else { return nil }
        
        // 2-2) 데코 합성 (해당 데코 키)
        let outlinedSize = outlined.size
        guard outlinedSize.width >= 1, outlinedSize.height >= 1 else { return nil }
        
        // 3) 최종 사이즈 계산 320×320 px
        let targetPx: CGFloat = 320
        let screenScale = UIScreen.main.scale
        
        let canvasPt = CGSize(width: targetPx / screenScale, height: targetPx / screenScale)
        let decoRatio: CGFloat = 0.90 // 데코 폭
        let offsetXRatio: CGFloat = 0.12 // getStickers의 16을 320px에 대한 값으로 반영
        let offsetYRatio: CGFloat = -0.18 // getStickers의 36을 320px에 대한 값으로 반영
        
        let decoWidthPt = canvasPt.width * decoRatio
        let offsetPtX = canvasPt.width * offsetXRatio
        let offsetPtY = canvasPt.height * offsetYRatio
        
        let sticker = ImageUtils.renderViewAsImage(
            ZStack {
                Image(uiImage: outlined)
                    .resizable()
                    .scaledToFit()
                    .frame(width: canvasPt.width, height: canvasPt.height)
                
                Image(style.stickerDecoString)
                    .resizable()
                    .scaledToFit()
                    .frame(width: decoWidthPt)
            }
            .offset(x: offsetPtX, y: offsetPtY), size: canvasPt
        )
        return sticker
    }
    
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
    
    /// 누끼 마스크 두 번 적용해 클리핑 이미지 생성
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
    
    /// 클리핑 이미지에 테두리 적용
    private func getOutlinedImage(for clippedImage: UIImage) -> [String : UIImage] {
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
    
    /// 테두리 적용한 이미지에 데코 이미지 zstack으로 넣기
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
