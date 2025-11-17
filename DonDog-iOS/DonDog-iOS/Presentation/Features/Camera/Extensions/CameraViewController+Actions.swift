//
//  CameraViewController+Actions.swift
//  DonDog-iOS
//
//  Created by Ito on 11/15/25.
//

import AVFoundation
import UIKit

extension CustomCameraViewController {
    @objc func capturePhoto() {
        guard isCaptureButtonEnabled else {
            return
        }
        HapticManager.shared.heavy()
        isCaptureButtonEnabled = false
        captureButton.isEnabled = false
        captureButton.alpha = 0.5
        
        if isCapturingFront && flashMode == .on {
            triggerScreenFlashAndCapture()
        } else {
            let settings = AVCapturePhotoSettings()
            if !isCapturingFront {
                settings.flashMode = flashMode
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    @objc func cancelTapped() {
        if isCapturingFront {
            delegate?.didCancel()
        } else {
            switchToFrontCamera()
        }
    }
    
    @objc func retakePhoto() {
        if isCapturingFront {
            isFrontPhotoConfirmed = false
            frontImage = nil
            
            updateUIForFrontPhotoConfirmation(isConfirmed: false)
            
            capturedImageView.isHidden = true
            videoPreviewLayer.isHidden = false
            
            isCaptureButtonEnabled = true
            captureButton.isEnabled = true
            captureButton.alpha = 1.0
        } else {
            isBackPhotoConfirmed = false
            backImage = nil
            
            updateUIForBackPhotoConfirmation(isConfirmed: false)
            
            capturedImageView.isHidden = true
            videoPreviewLayer.isHidden = false
            
            isCaptureButtonEnabled = true
            captureButton.isEnabled = true
            captureButton.alpha = 1.0
        }
    }
    
    @objc func proceedToNextStep() {
        if isCapturingFront {
            guard let frontImage = frontImage else { return }
            
            delegate?.didCaptureFrontImage(frontImage)
            switchToBackCamera()
        } else {
            guard let backImage = backImage else { return }
            delegate?.didCaptureBackImage(backImage)
            viewModel?.showCompleteView = true
        }
    }
    
    private func switchToBackCamera() {
        capturedImageView.isHidden = true
        videoPreviewLayer.isHidden = false
        
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("후면 카메라를 찾을 수 없습니다")
            return
        }
        
        currentCamera = backCamera
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("후면 카메라 설정 오류: \(error)")
        }
        
        isCapturingFront = false
        
        isCaptureButtonEnabled = true
        captureButton.isEnabled = true
        captureButton.alpha = 1.0
        
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.showGuideView = true
            self?.updateFlashButtonAppearance()
        }
        
        updateUIForBackCamera()
    }
    
    private func switchToFrontCamera() {
        capturedImageView.isHidden = true
        videoPreviewLayer.isHidden = false
        
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("전면 카메라를 찾을 수 없습니다")
            return
        }
        
        currentCamera = frontCamera
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            try frontCamera.lockForConfiguration()
            frontCamera.videoZoomFactor = 1.3
            frontCamera.unlockForConfiguration()
        } catch {
            print("전면 카메라 설정 오류: \(error)")
        }
        
        isCapturingFront = true
        frontImage = nil
        
        isCaptureButtonEnabled = true
        captureButton.isEnabled = true
        captureButton.alpha = 1.0
        
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.frontImage = nil
            self?.viewModel?.showGuideView = true
            self?.updateFlashButtonAppearance()
        }
        
        updateUIForCurrentState()
    }
    
    @objc func toggleFlash() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .off
        case .auto:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
        
        updateFlashButtonAppearance()
        
        HapticManager.shared.light()
    }
    
    private func triggerScreenFlashAndCapture() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.savedBrightness = UIScreen.main.brightness
            
            UIScreen.main.brightness = 1.0
        
            self.screenFlashOverlay.isHidden = false
            self.screenFlashOverlay.alpha = 1.0
            self.screenFlashOverlay.backgroundColor = .white
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                
                let settings = AVCapturePhotoSettings()
                self.photoOutput.capturePhoto(with: settings, delegate: self)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    
                    UIScreen.main.brightness = self.savedBrightness
                    
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                        self.screenFlashOverlay.alpha = 0.0
                    }, completion: { _ in
                        self.screenFlashOverlay.isHidden = true
                    })
                }
            }
        }
    }
}
