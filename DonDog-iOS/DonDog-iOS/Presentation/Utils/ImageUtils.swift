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
    private var mask: CIImage?

    private func renderToCIImage(image: UIImage) -> CIImage? {
        if let ciImage = image.ciImage {
            return ciImage
        } else if let cgImage = image.cgImage {
            return CIImage(cgImage: cgImage)
        } else {
            print("Failed to create CIImage - no underlying image data found")
            return nil
        }
    }
    
    private func renderToUIImage(image: CIImage) -> UIImage? {
        return UIImage(ciImage: image)
    }

    func makeMask(from image: UIImage) -> UIImage? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        guard let ciImage = renderToCIImage(image: image) else {
            print("Failed to convert UIImage to CIImage")
            return nil
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
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
            scaleX: ciImage.extent.width / mask.extent.width,
            y: ciImage.extent.height / mask.extent.height
        ))
        
        self.mask = resizedMask.cropped(to: ciImage.extent)
        
        return renderToUIImage(image: self.mask ?? CIImage())
    }

    private func applyingMask(to image: CIImage) -> CIImage? {
        let transparentBackground = CIImage(color: .clear).cropped(to: image.extent)
        
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = self.mask
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

    func makeSticker(with image: UIImage) -> UIImage? {
        guard let originalCIImage = renderToCIImage(image: image),
              let clippedCIImage = applyingMask(to: originalCIImage),
              let finalImage = renderToUIImage(ciImage: clippedCIImage, original: image) else {
            print("이미지 처리 실패")
            return nil
        }
        return finalImage
    }
}
