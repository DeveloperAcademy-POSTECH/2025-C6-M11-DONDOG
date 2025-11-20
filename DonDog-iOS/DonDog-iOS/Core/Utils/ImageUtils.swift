//
//  ImageUtils.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/12/25.
//

import Combine
import CoreImage.CIFilterBuiltins
import ImageIO
import SwiftUI
import Vision

final class ImageUtils {
    static func makeMask(from image: UIImage) -> CIImage? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        guard let ciImage = CIImage(image: image) else {
            print("UIImage -> CIImage 변환 실패")
            return nil
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
        } catch {
            print("Vision request 실패: \(error)")
            return nil
        }
        
        guard let maskBuffer = request.results?.first?.pixelBuffer else {
            print("마스크 생성 실패")
            return nil
        }
        
        var mask = CIImage(cvPixelBuffer: maskBuffer)
        
        let resizedMask = mask.transformed(by: CGAffineTransform(
            scaleX: ciImage.extent.width / mask.extent.width,
            y: ciImage.extent.height / mask.extent.height
        ))
        
        mask = resizedMask.cropped(to: ciImage.extent)
        
        return mask
    }
    
    static func applyingMask(to image: UIImage, with mask: CIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            print("UIImage -> CIImage 변환 실패")
            return nil
        }
        
        let transparentBackground = CIImage(color: .clear)
            .cropped(to: ciImage.extent)
        
        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.maskImage = mask
        filter.backgroundImage = transparentBackground
        
        guard let output = filter.outputImage else {
            print("마스크 적용 실패")
            return nil
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else {
            print("CGImage로 결과물 생성 실패")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
//    static func renderViewAsImage<V: View>(_ view: V, size: CGSize) -> UIImage {
//        let controller = UIHostingController(rootView: view)
//        // controller.view.bounds = CGRect(origin: .zero, size: size)
//        controller.view.frame  = CGRect(origin: .zero, size: size)
//        controller.view.backgroundColor = .clear
//        
//        controller.view.setNeedsLayout()
//        controller.view.layoutIfNeeded()
//        
//        let renderer = UIGraphicsImageRenderer(size: size)
//        return renderer.image { _ in
//            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
//        }
//    }
    
    static func renderViewAsImage<V: View>(_ view: V, size: CGSize) -> UIImage {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(
                content: view
                    .frame(width: size.width, height: size.height, alignment: .center)
                    .ignoresSafeArea()
            )
            renderer.scale = UIScreen.main.scale
            
            if let image = renderer.uiImage {
                return image
            }
        }
        
        // Fallback: UIHostingController + layer.render
        let controller = UIHostingController(
            rootView: view
                .frame(width: size.width, height: size.height, alignment: .center)
        )
        controller.view.backgroundColor = .clear
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.frame = CGRect(origin: .zero, size: size)
        
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            controller.view.layer.render(in: ctx.cgContext)
        }
    }
    
}
