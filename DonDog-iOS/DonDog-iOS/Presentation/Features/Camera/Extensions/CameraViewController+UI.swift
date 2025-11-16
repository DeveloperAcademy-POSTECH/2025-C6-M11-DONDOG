//
//  CameraViewController+.swift
//  DonDog-iOS
//
//  Created by Ito on 11/15/25.
//

import AVFoundation
import SwiftUI
import UIKit

extension CustomCameraViewController {
    func setupUI() {
        view.backgroundColor = .white
        
        setupCancelButton()
        if isStickerCamera {
            setupStickerGuide()
        } else {
            setupStepIndicator()
        }
        setupPreviewLayer()
        setupCaptureButton()
        if !isStickerCamera {
            setupBottomButtons()
        }
    }
    
    private func setupPreviewLayer() {
        previewContainerView.backgroundColor = .clear
        previewContainerView.clipsToBounds = true
        previewContainerView.layer.cornerRadius = 12
        
        view.addSubview(previewContainerView)
        previewContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        let topAnchor: NSLayoutYAxisAnchor
        let topSpacing: CGFloat
        if isStickerCamera {
            if stickerGuideContainer.superview != nil {
                topAnchor = stickerGuideContainer.bottomAnchor
                topSpacing = 24
            } else {
                topAnchor = cancelButton.bottomAnchor
                topSpacing = 24
            }
        } else {
            topAnchor = stepIndicatorContainer.bottomAnchor
            topSpacing = 20
        }
        
        NSLayoutConstraint.activate([
            previewContainerView.topAnchor.constraint(equalTo: topAnchor, constant: topSpacing),
            previewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            previewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            previewContainerView.heightAnchor.constraint(equalTo: previewContainerView.widthAnchor, multiplier: 4.0/3.0)
        ])
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.cornerRadius = 12
        videoPreviewLayer.frame = previewContainerView.bounds
        previewContainerView.layer.addSublayer(videoPreviewLayer)
        
        capturedImageView.contentMode = .scaleAspectFill
        capturedImageView.clipsToBounds = true
        capturedImageView.layer.cornerRadius = 12
        capturedImageView.isHidden = true
        
        previewContainerView.addSubview(capturedImageView)
        capturedImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            capturedImageView.topAnchor.constraint(equalTo: previewContainerView.topAnchor),
            capturedImageView.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor),
            capturedImageView.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor),
            capturedImageView.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor)
        ])
    }
    
    private func setupCaptureButton() {
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 36
        captureButton.layer.borderWidth = 3
        captureButton.layer.borderColor = Color.ppPrime.uiColor.cgColor
        
        captureButtonInnerCircle.backgroundColor = .ppPrime
        captureButtonInnerCircle.layer.cornerRadius = 28
        captureButtonInnerCircle.isUserInteractionEnabled = false
        captureButton.addSubview(captureButtonInnerCircle)
        captureButtonInnerCircle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureButtonInnerCircle.centerXAnchor.constraint(equalTo: captureButton.centerXAnchor),
            captureButtonInnerCircle.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            captureButtonInnerCircle.widthAnchor.constraint(equalToConstant: 56),
            captureButtonInnerCircle.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        
        view.addSubview(captureButton)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    private func setupCancelButton() {
        let chevronImage = UIImage(systemName: "chevron.left")
        let resizedImage = chevronImage?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        cancelButton.setImage(resizedImage, for: .normal)
        cancelButton.tintColor = Color.ppBlack.uiColor
        
        cancelButton.contentMode = .center
        cancelButton.imageView?.contentMode = .scaleAspectFit
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 11),
            cancelButton.widthAnchor.constraint(equalToConstant: 24),
            cancelButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupBottomButtons() {
        view.addSubview(bottomButtonContainer)
        bottomButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomButtonContainer.isHidden = true
        
        NSLayoutConstraint.activate([
            bottomButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bottomButtonContainer.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        retakeButton.backgroundColor = .ppGray400
        retakeButton.layer.cornerRadius = 12
        retakeButton.setTitle("다시 찍기", for: .normal)
        retakeButton.setTitleColor(.ppWhite, for: .normal)
        retakeButton.titleLabel?.font = UIFont(name: FontName.pretendardMedium.rawValue, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        retakeButton.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        
        bottomButtonContainer.addSubview(retakeButton)
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        
        nextButton.backgroundColor = .ppPrime
        nextButton.layer.cornerRadius = 12
        nextButton.setTitle("다음", for: .normal)
        nextButton.setTitleColor(.ppWhite, for: .normal)
        nextButton.titleLabel?.font = UIFont(name: FontName.pretendardMedium.rawValue, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        nextButton.addTarget(self, action: #selector(proceedToNextStep), for: .touchUpInside)
        
        bottomButtonContainer.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            retakeButton.leadingAnchor.constraint(equalTo: bottomButtonContainer.leadingAnchor),
            retakeButton.centerYAnchor.constraint(equalTo: bottomButtonContainer.centerYAnchor),
            retakeButton.widthAnchor.constraint(equalTo: nextButton.widthAnchor),
            retakeButton.heightAnchor.constraint(equalToConstant: 52),
            
            nextButton.leadingAnchor.constraint(equalTo: retakeButton.trailingAnchor, constant: 12),
            nextButton.trailingAnchor.constraint(equalTo: bottomButtonContainer.trailingAnchor),
            nextButton.centerYAnchor.constraint(equalTo: bottomButtonContainer.centerYAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
}
