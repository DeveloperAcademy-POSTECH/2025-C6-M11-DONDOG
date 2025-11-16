//
//  CameraViewController+State.swift
//  DonDog-iOS
//
//  Created by Ito on 11/15/25.
//

import UIKit

extension CustomCameraViewController {
    func updateUIForCurrentState() {
        DispatchQueue.main.async {
            if self.isCapturingFront {
                self.captureButton.setTitle("", for: .normal)
            } else {
                if self.isStickerCamera {
                    self.captureButton.setTitle("", for: .normal)
                } else {
                    self.captureButton.setTitle("", for: .normal)
                }
                self.captureButton.setTitle("", for: .normal)
            }
            
            self.updateStepIndicator()
        }
    }
    
    func updateUIForFrontPhotoConfirmation(isConfirmed: Bool) {
        guard !isStickerCamera else { return }
        
        isFrontPhotoConfirmed = isConfirmed
        
        DispatchQueue.main.async {
            if isConfirmed {
                self.step1Label.isHidden = true
                self.step1CheckmarkImageView.isHidden = false
                self.step1Circle.backgroundColor = .ddAlert
                
                // Step 1 펄스 애니메이션 멈춤
                self.step1PulseView.isHidden = true
                self.removePulseAnimation(from: self.step1PulseView)
                
                self.bottomButtonContainer.isHidden = false
                self.captureButton.isHidden = true
            } else {
                self.step1Label.isHidden = false
                self.step1CheckmarkImageView.isHidden = true
                
                // 다시 찍기 시 Step 1 펄스 애니메이션 다시 시작
                self.step1PulseView.isHidden = false
                self.addPulseAnimation(to: self.step1PulseView)
                
                self.bottomButtonContainer.isHidden = true
                self.captureButton.isHidden = false
            }
        }
    }
    
    func updateUIForBackPhotoConfirmation(isConfirmed: Bool) {
        isBackPhotoConfirmed = isConfirmed
        
        DispatchQueue.main.async {
            if isConfirmed {
                self.step2Label.isHidden = true
                self.step2CheckmarkImageView.isHidden = false
                self.step2Circle.backgroundColor = .ddAlert
                
                // Step 2 펄스 애니메이션 멈춤
                self.step2PulseView.isHidden = true
                self.removePulseAnimation(from: self.step2PulseView)
                
                self.bottomButtonContainer.isHidden = false
                self.captureButton.isHidden = true
            } else {
                self.step2Label.isHidden = false
                self.step2CheckmarkImageView.isHidden = true
                
                // 다시 찍기 시 Step 2 펄스 애니메이션 다시 시작
                self.step2PulseView.isHidden = false
                self.addPulseAnimation(to: self.step2PulseView)
                
                self.bottomButtonContainer.isHidden = true
                self.captureButton.isHidden = false
            }
        }
    }
    
    func updateUIForBackCamera() {
        DispatchQueue.main.async {
            self.updateStepIndicator()
            
            self.bottomButtonContainer.isHidden = true
            self.captureButton.isHidden = false
            
            self.isFrontPhotoConfirmed = false
        }
    }
    
    func resetCameraState() {
        DispatchQueue.main.async {
            self.isCapturingFront = true
            self.frontImage = nil
            self.backImage = nil
            self.capturedImageView.isHidden = true
            self.videoPreviewLayer.isHidden = false
            self.isCaptureButtonEnabled = true
            self.captureButton.isEnabled = true
            self.captureButton.alpha = 1.0
            
            self.isFrontPhotoConfirmed = false
            self.isBackPhotoConfirmed = false
            
            self.step1Label.isHidden = false
            self.step1CheckmarkImageView.isHidden = true
            self.step1Circle.backgroundColor = .ddAlert
            self.step1Label.textColor = .white
            
            self.step2Label.isHidden = false
            self.step2CheckmarkImageView.isHidden = true
            self.step2Circle.backgroundColor = .ddGray300
            self.step2Label.textColor = .white
            
            self.bottomButtonContainer.isHidden = true
            self.captureButton.isHidden = false
            
            self.updateUIForCurrentState()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.performCameraSwitchToFront()
            }
        }
    }
}
