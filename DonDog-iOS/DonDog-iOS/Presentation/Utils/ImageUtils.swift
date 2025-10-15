//
//  ImageUtils.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/12/25.
//

import Combine
import SwiftUI
import Vision
import CoreImage.CIFilterBuiltins

final class ImageUtils: ObservableObject {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    private func renderToCIImage(image: UIImage) -> CIImage? {
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return nil
        }
        return ciImage
    }

    private func makeMask(image: CIImage) -> CIImage? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print("Vision request failed: \(error)")
            return nil
        }
        
        guard let maskBuffer = request.results?.first?.pixelBuffer else {
            print("No mask results found")
            return nil
        }
        
        let mask = CIImage(cvPixelBuffer: maskBuffer)
        let resizedMask = mask.transformed(by: CGAffineTransform(
            scaleX: image.extent.width / mask.extent.width,
            y: image.extent.height / mask.extent.height
        ))
        return resizedMask.cropped(to: image.extent)
    }

    private func applyingMask(mask: CIImage, to image: CIImage) -> CIImage? {
        let transparentBackground = CIImage(color: .clear).cropped(to: image.extent)
        
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = transparentBackground
        return filter.outputImage
    }

    private func renderToUIImage(ciImage: CIImage, original: UIImage) -> UIImage? {
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage, scale: original.scale, orientation: original.imageOrientation)
    }

    static func makeSticker(with image: UIImage) -> UIImage? {
        let utils = ImageUtils()
        
        guard let originalCIImage = utils.renderToCIImage(image: image),
              let mask = utils.makeMask(image: originalCIImage),
              let clippedCIImage = utils.applyingMask(mask: mask, to: originalCIImage),
              let finalImage = utils.renderToUIImage(ciImage: clippedCIImage, original: image) else {
            print("이미지 처리 실패")
            return nil
        }
        return finalImage
    }
}
