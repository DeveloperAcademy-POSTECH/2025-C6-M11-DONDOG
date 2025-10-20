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
import ImageIO

final class ImageUtils: ObservableObject {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var mask: CIImage?
    
    private func renderToCIImage(image: UIImage) -> CIImage? {
        let exif = Int32(image.imageOrientation.cgImagePropertyOrientation.rawValue)
        if let ciImage = image.ciImage {
            return ciImage.oriented(forExifOrientation: exif)
        } else if let cgImage = image.cgImage {
            return CIImage(cgImage: cgImage).oriented(forExifOrientation: exif)
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
        return UIImage(cgImage: cgImage, scale: original.scale, orientation: .up)
    }
    
    func makeSticker(with image: UIImage) -> UIImage? {
        guard let originalCIImage = renderToCIImage(image: image) else {
            print("renderToCIImage 실패")
            return nil
        }
        
        guard let firstMaskUI = self.makeMask(from: image),
              var firstMaskCI = renderToCIImage(image: firstMaskUI) else {
            print("첫 번째 mask 실패")
            return nil
        }
        
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = firstMaskCI
        blurFilter.radius = 2
        if let blurred = blurFilter.outputImage {
            firstMaskCI = blurred.cropped(to: originalCIImage.extent)
        }
        
        self.mask = firstMaskCI
        
        guard let clippedCIImage = applyingMask(to: originalCIImage) else {
            print("applyingMask 실패")
            return nil
        }
        
        guard let secondMaskUI = self.makeMask(from: UIImage(ciImage: clippedCIImage)),
              var secondMaskCI = renderToCIImage(image: secondMaskUI) else {
            print("두 번째 mask 실패")
            return renderToUIImage(ciImage: clippedCIImage, original: image)
        }
        
        blurFilter.inputImage = secondMaskCI
        blurFilter.radius = 1.5
        if let blurredSecond = blurFilter.outputImage {
            secondMaskCI = blurredSecond.cropped(to: clippedCIImage.extent)
        }
        
        self.mask = secondMaskCI
        
        guard let finalClipped = applyingMask(to: clippedCIImage),
              let finalImage = renderToUIImage(ciImage: finalClipped, original: image) else {
            return renderToUIImage(ciImage: clippedCIImage, original: image)
        }
        
        return finalImage
    }
}

private extension UIImage.Orientation {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:
            return .up
        }
    }
}
