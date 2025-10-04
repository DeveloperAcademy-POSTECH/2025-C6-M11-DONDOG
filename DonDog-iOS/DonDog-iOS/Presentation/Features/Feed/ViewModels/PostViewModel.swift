//
//  PostViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/4/25.
//

import Combine
import SwiftUI
import Vision
import CoreImage.CIFilterBuiltins

final class PostViewModel: ObservableObject {
    // TODO: print문 로그로 변경, 예외 처리
    @Published var image: UIImage? = nil
    private let ciContext = CIContext()

    private func getImage() {
        image = UIImage(named: "StickerImage")
    }

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
        let resizedMask = mask.transformed(by: CGAffineTransform(scaleX: image.extent.width / mask.extent.width,
                                                                 y: image.extent.height / mask.extent.height))
        return resizedMask.cropped(to: image.extent)

        }


    private func applyingMask(mask: CIImage, to image: CIImage) -> CIImage? {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage
    }

    private func renderToUIImage(ciImage: CIImage, original: UIImage) -> UIImage? {
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        return UIImage(cgImage: cgImage, scale: original.scale, orientation: original.imageOrientation)
    }


    func makeSticker() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.getImage()

            guard let image = self.image,
                  let originalCIImage = self.renderToCIImage(image: image),
                  let mask = self.makeMask(image: originalCIImage),
                  let clippedCIImage = self.applyingMask(mask: mask, to: originalCIImage),
                  let finalImage = self.renderToUIImage(ciImage: clippedCIImage, original: image) else {
                print("Image processing failed")
                return
            }

            DispatchQueue.main.async {
                self.image = finalImage
            }
        }
    }

}
