//
//  CameraViewController+PhotoCapture.swift
//  DonDog-iOS
//
//  Created by Ito on 11/15/25.
//

import AVFoundation
import SwiftUI
import UIKit

extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              var image = UIImage(data: imageData) else {
            print("이미지 변환 실패")
            return
        }
        
        if isCapturingFront {
            image = flipImageHorizontally(image) ?? image
            frontImage = image
            
            DispatchQueue.main.async {
                self.showCapturedImage(image)
                self.updateUIForFrontPhotoConfirmation(isConfirmed: true)
            }
            
            if self.isFrontOnly {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.presentStickerConfirm(with: image)
                }
            }
        } else {
            backImage = image
            delegate?.didCaptureBackImage(image)
            
            DispatchQueue.main.async {
                self.showCapturedImage(image)
                self.updateUIForBackPhotoConfirmation(isConfirmed: true)
            }
        }
    }
    
    private func showCapturedImage(_ image: UIImage) {
        videoPreviewLayer.isHidden = true
        capturedImageView.image = image
        capturedImageView.isHidden = false
    }
    
    private func flipImageHorizontally(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let flippedImage = UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: .leftMirrored
        )
        
        return flippedImage
    }
    
    private func presentStickerConfirm(with image: UIImage) {
        Task { [weak self] in
            guard let self = self else { return }
            let sticker = await StickerService().makeSticker(from: image)
            let finalImage = sticker
            
            let confirmVC = UIHostingController(
                rootView: StickerConfirmView(
                    viewModel: StickerConfirmViewModel(
                        image: finalImage,
                        onDone: { [weak self] _ in
                            self?.dismissAllModals()
                        }
                    ),
                    route: .camera,
                    onRetake: { [weak self] in
                        self?.presentedViewController?.dismiss(animated: true) {
                            guard let self = self else { return }
                            self.resetCameraState()
                        }
                    },
                    onClose: { [weak self] in
                        self?.dismissAllModals()
                    }
                )
            )
            confirmVC.modalPresentationStyle = .fullScreen
            confirmVC.modalTransitionStyle = .crossDissolve
            self.present(confirmVC, animated: false)
        }
    }
    
    private func dismissAllModals(animated: Bool = true) {
        DispatchQueue.main.async {
            if let presenter = self.presentingViewController {
                presenter.dismiss(animated: animated)
            } else {
                self.dismiss(animated: animated)
            }
        }
    }
}
