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
            
            if self.isStickerCamera {
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
                    viewModel: StickerConfirmViewModel(image: finalImage),
                    route: .camera,
                    onRetake: { [weak self] in
                        guard let self = self else { return }
                        self.presentedViewController?.dismiss(animated: true) {
                            self.navigationController?.setNavigationBarHidden(true, animated: false)
                            self.navigationItem.hidesBackButton = true
                            self.resetCameraState()
                        }
                    },
                    onComplete: { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true) {
                            self.delegate?.didCancel()
                        }
                    },
                    onUploaded: { tags in
                        Task {
                            await StickerGridService.shared.reloadSticker(tags: tags)
                        }
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
