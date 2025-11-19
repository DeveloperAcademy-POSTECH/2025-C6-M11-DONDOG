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
        
        // 0) 입력 프리-리사이즈 (성능용, 최대 변 500pt)
        let originalSize = image.size
        let preMaxEdgePt: CGFloat = 400
        let preScale = min(preMaxEdgePt / max(originalSize.width, originalSize.height), 1)
        let preSize = CGSize(width: originalSize.width * preScale, height: originalSize.height * preScale)
        let preFormat = UIGraphicsImageRendererFormat.default()
        preFormat.scale = 1
        let preRenderer = UIGraphicsImageRenderer(size: preSize, format: preFormat)
        let resizedImage = preRenderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: preSize))
        }
        
        // 1) 누끼
        let clippedRaw = getClippedImage(of: resizedImage)
        // 알파 있는 부분만 타이트하게 자르기
        let tightClipped = clippedRaw.croppedToAlphaBounds(padding: 10)
        guard tightClipped.size.width >= 1, tightClipped.size.height >= 1 else { return nil }

        // 1-1) 3:4 캔버스 하단 정렬 (세로가 더 긴 비율)
        let clipped = tightClipped.paddedToThreeByFourBottomAligned()
        
        // 2) 스타일 해석 (사용자 역할에 따라 배경 이미지 선택)
        let role = connectUserInfo.myRole
        guard let style = StickerStyleData.style(forTitle: title, role: role) else { return nil }
        
        // 2-1) ppWhite 보더 - 모든 스티커 동일
        let uiColor = UIColor.ppWhite
        guard let outlined = clipped.addOutline(thickness: 10, color: uiColor) else { return nil }
        let outlinedSize = outlined.size
        guard outlinedSize.width >= 1, outlinedSize.height >= 1 else { return nil }
        
        let layout = style.layout

        let sticker = ImageUtils.renderViewAsImage(
            ZStack {
                if layout.outlinedOnTop {
                    Image(style.stickerDecoBackground)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 360, height: 300)

                    HStack {
                        VStack {
                            Image(uiImage: outlined)
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: layout.outlinedSize.width,
                                    height: layout.outlinedSize.height
                                )
                                .offset(layout.outlinedOffset)
                            Spacer()
                        }
                        Spacer()
                    }
                } else {
                    HStack {
                        VStack {
                            Image(uiImage: outlined)
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: layout.outlinedSize.width,
                                    height: layout.outlinedSize.height
                                )
                                .offset(layout.outlinedOffset)
                            
                            Spacer()
                        }
                        Spacer()
                    }

                    Image(style.stickerDecoBackground)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 360, height: 300)
                }
            }
            .frame(width: 360, height: 300),
            size: CGSize(width: 360, height: 300)
        )
        
        return sticker

        /// 최종 스티커 이미지를 한 번 더 다운스케일
//        let finalSticker = resizedForStickerUpload(sticker, maxEdge: 360)
//        return finalSticker
//        func resizedForStickerUpload(_ image: UIImage, maxEdge: CGFloat = 360) -> UIImage {
//            let size = image.size
//            let maxOriginalEdge = max(size.width, size.height)
//            guard maxOriginalEdge > maxEdge, maxOriginalEdge > 0 else {
//                return image
//            }
//
//            let scale = maxEdge / maxOriginalEdge
//            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
//
//            let format = UIGraphicsImageRendererFormat.default()
//            format.scale = 1
//
//            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
//            let resized = renderer.image { _ in
//                image.draw(in: CGRect(origin: .zero, size: newSize))
//            }
//
//            return resized
//        }
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

extension UIImage {
    /// 알파가 0이 아닌 픽셀 영역만 감싸도록 잘라내기 (여백 제거)
    func croppedToAlphaBounds(padding: CGFloat = 0) -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else {
            return self
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let alpha = ptr[offset + 3]
                if alpha > 0 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        // 알파 있는 픽셀 없으면 원본 리턴
        if minX > maxX || minY > maxY { return self }

        var cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        // 살짝 패딩을 주고, 이미지 범위 안으로 클램프
        cropRect = cropRect
            .insetBy(dx: -padding, dy: -padding)
            .intersection(CGRect(x: 0, y: 0, width: width, height: height))

        guard let croppedCG = cgImage.cropping(to: cropRect) else { return self }

        return UIImage(
            cgImage: croppedCG,
            scale: self.scale,
            orientation: self.imageOrientation
        )
    }

    /// 현재 이미지를 세로로 더 긴 3:4 비율 캔버스의 하단 중앙에 배치하여 반환
    func paddedToThreeByFourBottomAligned(backgroundColor: UIColor = .clear) -> UIImage {
        let w = size.width
        let h = size.height

        // 사이즈가 유효하지 않으면 원본 반환
        guard w > 0, h > 0 else { return self }

        let aspect: CGFloat = 3.0 / 4.0 // width : height = 3:4 (세로가 긴 비율)

        // 너비를 기준으로 3:4 비율의 높이를 계산
        let widthBasedHeight = w / aspect

        let canvasSize: CGSize
        if widthBasedHeight >= h {
            // 너비는 그대로 두고, 높이를 3:4 비율에 맞추면 클리핑 이미지가 모두 들어감
            canvasSize = CGSize(width: w, height: widthBasedHeight)
        } else {
            // 높이를 기준으로 3:4 비율의 너비를 계산
            let heightBasedWidth = h * aspect
            // 이 경우 높이는 그대로 두고, 너비를 3:4 비율에 맞춘다
            canvasSize = CGSize(width: heightBasedWidth, height: h)
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        let result = renderer.image { context in
            // 배경 채우기
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))

            // 클리핑 이미지를 캔버스 하단 중앙에 배치
            let originX = (canvasSize.width - w) / 2
            let originY = canvasSize.height - h
            let drawRect = CGRect(origin: CGPoint(x: originX, y: originY), size: size)

            self.draw(in: drawRect)
        }

        return result
    }
}
