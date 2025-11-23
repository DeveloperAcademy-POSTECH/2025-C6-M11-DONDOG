//
//  CameraViewController+StepIndicator.swift
//  DonDog-iOS
//
//  Created by Ito on 11/15/25.
//

import UIKit

extension CustomCameraViewController {
    func setupStepIndicator() {
        setupStepIndicatorContainer()
        setupStep1Circle()
        setupStepDots()
        setupStep2Circle()
        
        updateStepIndicator()
    }
    
    func setupStepIndicatorContainer() {
        view.addSubview(stepIndicatorContainer)
        stepIndicatorContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stepIndicatorContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepIndicatorContainer.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 24),
            stepIndicatorContainer.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func setupStep1Circle() {
        step1PulseView.backgroundColor = UIColor.ppSubPrime.withAlphaComponent(0.7)
        step1PulseView.layer.cornerRadius = 12
        stepIndicatorContainer.addSubview(step1PulseView)
        step1PulseView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step1PulseView.centerXAnchor.constraint(equalTo: stepIndicatorContainer.leadingAnchor, constant: 32),
            step1PulseView.centerYAnchor.constraint(equalTo: stepIndicatorContainer.topAnchor, constant: 20),
            step1PulseView.widthAnchor.constraint(equalToConstant: 24),
            step1PulseView.heightAnchor.constraint(equalToConstant: 24)
        ])
        step1PulseView.isHidden = true
        
        step1Circle.backgroundColor = .ppSubPrime
        step1Circle.layer.cornerRadius = 12
        stepIndicatorContainer.addSubview(step1Circle)
        step1Circle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step1Circle.leadingAnchor.constraint(equalTo: stepIndicatorContainer.leadingAnchor, constant: 20),
            step1Circle.topAnchor.constraint(equalTo: stepIndicatorContainer.topAnchor, constant: 8),
            step1Circle.widthAnchor.constraint(equalToConstant: 24),
            step1Circle.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        step1Label.text = "1"
        step1Label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        step1Label.textColor = .white
        step1Label.textAlignment = .center
        step1Circle.addSubview(step1Label)
        step1Label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step1Label.centerXAnchor.constraint(equalTo: step1Circle.centerXAnchor),
            step1Label.centerYAnchor.constraint(equalTo: step1Circle.centerYAnchor)
        ])
        
        step1TextLabel.text = "셀카 촬영"
        step1TextLabel.font = UIFont(name: FontName.pretendardMedium.rawValue, size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
        step1TextLabel.textColor = .ppSubPrime
        step1TextLabel.textAlignment = .center
        stepIndicatorContainer.addSubview(step1TextLabel)
        step1TextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step1TextLabel.centerXAnchor.constraint(equalTo: step1Circle.centerXAnchor),
            step1TextLabel.topAnchor.constraint(equalTo: step1Circle.bottomAnchor, constant: 8)
        ])
        
        step1CheckmarkImageView.image = UIImage(systemName: "checkmark")
        step1CheckmarkImageView.tintColor = .white
        step1CheckmarkImageView.contentMode = .scaleAspectFit
        step1CheckmarkImageView.isHidden = true
        
        step1Circle.addSubview(step1CheckmarkImageView)
        step1CheckmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step1CheckmarkImageView.centerXAnchor.constraint(equalTo: step1Circle.centerXAnchor),
            step1CheckmarkImageView.centerYAnchor.constraint(equalTo: step1Circle.centerYAnchor),
            step1CheckmarkImageView.widthAnchor.constraint(equalToConstant: 14),
            step1CheckmarkImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    func setupStepDots() {
        stepIndicatorContainer.addSubview(stepDotsContainer)
        stepDotsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let dotsCount = 10
        let dotWidth: CGFloat = 4
        let dotSpacing: CGFloat = 16
        let containerWidth = CGFloat(dotsCount - 1) * dotSpacing + dotWidth
        
        NSLayoutConstraint.activate([
            stepDotsContainer.leadingAnchor.constraint(equalTo: step1Circle.trailingAnchor, constant: 8),
            stepDotsContainer.centerYAnchor.constraint(equalTo: step1Circle.centerYAnchor),
            stepDotsContainer.widthAnchor.constraint(equalToConstant: containerWidth),
            stepDotsContainer.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        for i in 0..<dotsCount {
            let dot = UIView()
            let alpha = 1.0 - (CGFloat(i) * 0.08)
            dot.backgroundColor = UIColor.ppSubPrime.withAlphaComponent(alpha)
            dot.layer.cornerRadius = 2
            stepDotsContainer.addSubview(dot)
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.centerYAnchor.constraint(equalTo: stepDotsContainer.centerYAnchor),
                dot.leadingAnchor.constraint(equalTo: stepDotsContainer.leadingAnchor, constant: CGFloat(i) * dotSpacing),
                dot.widthAnchor.constraint(equalToConstant: dotWidth),
                dot.heightAnchor.constraint(equalToConstant: dotWidth)
            ])
        }
    }
    
    func updateStepDots() {
        let dots = stepDotsContainer.subviews
        for (index, dot) in dots.enumerated() {
            if isCapturingFront {
                let alpha = 1.0 - (CGFloat(index) * 0.08)
                dot.backgroundColor = UIColor.ppSubPrime.withAlphaComponent(alpha)
            } else {
                let alpha = 0.2 + (CGFloat(index) * 0.08)
                dot.backgroundColor = UIColor.ppSubPrime.withAlphaComponent(alpha)
            }
        }
    }
    
    func setupStep2Circle() {
        step2PulseView.backgroundColor = UIColor.ppSubPrime.withAlphaComponent(0.7)
        step2PulseView.layer.cornerRadius = 12
        stepIndicatorContainer.addSubview(step2PulseView)
        step2PulseView.translatesAutoresizingMaskIntoConstraints = false
        step2PulseView.isHidden = true
        
        step2Circle.backgroundColor = .ppGray300
        step2Circle.layer.cornerRadius = 12
        stepIndicatorContainer.addSubview(step2Circle)
        step2Circle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step2Circle.leadingAnchor.constraint(equalTo: stepDotsContainer.trailingAnchor, constant: 8),
            step2Circle.topAnchor.constraint(equalTo: stepIndicatorContainer.topAnchor, constant: 8),
            step2Circle.trailingAnchor.constraint(lessThanOrEqualTo: stepIndicatorContainer.trailingAnchor, constant: -20),
            step2Circle.widthAnchor.constraint(equalToConstant: 24),
            step2Circle.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // step2PulseView를 step2Circle과 같은 위치에 배치
        NSLayoutConstraint.activate([
            step2PulseView.centerXAnchor.constraint(equalTo: step2Circle.centerXAnchor),
            step2PulseView.centerYAnchor.constraint(equalTo: step2Circle.centerYAnchor),
            step2PulseView.widthAnchor.constraint(equalToConstant: 24),
            step2PulseView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        step2Label.text = "2"
        step2Label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        step2Label.textColor = .white
        step2Label.textAlignment = .center
        step2Circle.addSubview(step2Label)
        step2Label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step2Label.centerXAnchor.constraint(equalTo: step2Circle.centerXAnchor),
            step2Label.centerYAnchor.constraint(equalTo: step2Circle.centerYAnchor)
        ])
        
        step2TextLabel.text = "배경 촬영"
        step2TextLabel.font = UIFont(name: FontName.pretendardMedium.rawValue, size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
        step2TextLabel.textColor = .ppGray300
        step2TextLabel.textAlignment = .center
        stepIndicatorContainer.addSubview(step2TextLabel)
        step2TextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step2TextLabel.centerXAnchor.constraint(equalTo: step2Circle.centerXAnchor),
            step2TextLabel.topAnchor.constraint(equalTo: step2Circle.bottomAnchor, constant: 8)
        ])
        
        step2CheckmarkImageView.image = UIImage(systemName: "checkmark")
        step2CheckmarkImageView.tintColor = .white
        step2CheckmarkImageView.contentMode = .scaleAspectFit
        step2CheckmarkImageView.isHidden = true
        
        step2Circle.addSubview(step2CheckmarkImageView)
        step2CheckmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            step2CheckmarkImageView.centerXAnchor.constraint(equalTo: step2Circle.centerXAnchor),
            step2CheckmarkImageView.centerYAnchor.constraint(equalTo: step2Circle.centerYAnchor),
            step2CheckmarkImageView.widthAnchor.constraint(equalToConstant: 14),
            step2CheckmarkImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    func updateStepIndicator() {
        guard !isStickerCamera else { return }
        
        if isCapturingFront {
            step1Circle.backgroundColor = .ppSubPrime
            step1Label.isHidden = false
            step1CheckmarkImageView.isHidden = true
            step1Label.textColor = .white
            step1TextLabel.textColor = .ppSubPrime
            
            step1PulseView.isHidden = false
            addPulseAnimation(to: step1PulseView)
            
            step2PulseView.isHidden = true
            removePulseAnimation(from: step2PulseView)
            
            step2Circle.backgroundColor = .ppGray300
            step2Label.isHidden = false
            step2CheckmarkImageView.isHidden = true
            step2Label.textColor = .white
            step2TextLabel.textColor = .ppGray300
        } else {
            step1Circle.backgroundColor = .ppGray300
            step1Label.isHidden = true
            step1CheckmarkImageView.isHidden = false
            step1TextLabel.textColor = .ppGray300
            
            step1PulseView.isHidden = true
            removePulseAnimation(from: step1PulseView)
            
            step2Circle.backgroundColor = .ppSubPrime
            step2Label.isHidden = false
            step2CheckmarkImageView.isHidden = true
            step2Label.textColor = .white
            step2TextLabel.textColor = .ppSubPrime
            
            step2PulseView.isHidden = false
            addPulseAnimation(to: step2PulseView)
        }
        
        updateStepDots()
    }
    
    func addPulseAnimation(to view: UIView) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 2.0
        pulseAnimation.duration = 1.0
        pulseAnimation.repeatCount = .greatestFiniteMagnitude
        pulseAnimation.autoreverses = false
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.7
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 1.0
        opacityAnimation.repeatCount = .greatestFiniteMagnitude
        opacityAnimation.autoreverses = false
        
        view.layer.add(pulseAnimation, forKey: "pulseScale")
        view.layer.add(opacityAnimation, forKey: "pulseOpacity")
    }
    
    func removePulseAnimation(from view: UIView) {
        view.layer.removeAnimation(forKey: "pulseScale")
        view.layer.removeAnimation(forKey: "pulseOpacity")
    }
}
