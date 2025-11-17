//
//  CameraViewController+Focus.swift
//  DonDog-iOS
//
//  Created by Ito on 11/17/25.
//

import AVFoundation
import UIKit

extension CustomCameraViewController {
    
    func setupFocusIndicator() {
        focusIndicatorView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        focusIndicatorView.layer.borderWidth = 2
        focusIndicatorView.layer.borderColor = UIColor.white.cgColor
        focusIndicatorView.layer.cornerRadius = 40
        focusIndicatorView.backgroundColor = .clear
        focusIndicatorView.isHidden = true
        previewContainerView.addSubview(focusIndicatorView)
    }
    
    func setupTapGestureForFocus() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleFocusTap(_:)))
        previewContainerView.addGestureRecognizer(tapGesture)
        previewContainerView.isUserInteractionEnabled = true
    }
    
    @objc func handleFocusTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: previewContainerView)
        
        // Preview 영역 내에서만 동작하도록 체크
        guard previewContainerView.bounds.contains(location) else { return }
        
        // 카메라 좌표계로 변환
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
        
        // 초점 설정
        setFocusPoint(devicePoint, at: location)
        
        // 초점 표시 애니메이션
        showFocusIndicator(at: location)
    }
    
    private func setFocusPoint(_ point: CGPoint, at location: CGPoint) {
        guard let device = currentCamera else { return }
        
        // 기존 관찰 제거
        focusObservation?.invalidate()
        
        do {
            try device.lockForConfiguration()
            
            // 초점 모드 지원 확인
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            // 노출 모드 지원 확인
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
            
            // 초점 상태 관찰 시작
            observeFocusState()
        } catch {
            print("초점 설정 오류: \(error)")
        }
    }
    
    private func observeFocusState() {
        guard let device = currentCamera else { return }
        
        // 기존 관찰 제거
        focusObservation?.invalidate()
        
        // 초점 조정 중일 때는 노란색, 완료되면 초록색으로 변경
        focusObservation = device.observe(\.isAdjustingFocus, options: [.new]) { [weak self] device, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if device.isAdjustingFocus {
                    // 초점 잡는 중: 노란색
                    self.updateFocusIndicatorColor(.systemYellow)
                } else {
                    // 초점 완료: 초록색으로 변경 후 잠시 유지
                    self.updateFocusIndicatorColor(.systemGreen)
                    
                    // 초점 완료 후 0.5초 뒤 페이드 아웃
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.fadeOutFocusIndicator()
                    }
                }
            }
        }
    }
    
    private func updateFocusIndicatorColor(_ color: UIColor) {
        focusIndicatorView.layer.borderColor = color.cgColor
    }
    
    private func showFocusIndicator(at location: CGPoint) {
        // 애니메이션 중인 경우 presentation layer의 현재 값을 가져와서 부드럽게 전환
        var currentAlpha = focusIndicatorView.alpha
        var currentScale: CGFloat = 1.0
        
        // 애니메이션 중이면 presentation layer의 현재 값을 가져옴
        if let presentationLayer = focusIndicatorView.layer.presentation(),
           focusIndicatorView.layer.animationKeys()?.isEmpty == false {
            currentAlpha = CGFloat(presentationLayer.opacity)
            
            let transform = focusIndicatorView.transform
            currentScale = sqrt(transform.a * transform.a + transform.b * transform.b)
        }
        
        // 기존 애니메이션 제거
        focusIndicatorView.layer.removeAllAnimations()
        
        // 초점 표시 뷰 위치 설정
        focusIndicatorView.center = location
        focusIndicatorView.isHidden = false
        
        // 초점 잡는 중 색상으로 시작 (노란색)
        updateFocusIndicatorColor(.systemYellow)
        
        // 현재 상태에서 시작 (깜빡임 방지)
        // alpha가 충분히 높으면 현재 값 유지, 낮으면 1.0으로 리셋
        let startAlpha = currentAlpha > 0.3 ? currentAlpha : 1.0
        let startScale = currentAlpha > 0.3 ? currentScale : 1.3
        
        focusIndicatorView.alpha = startAlpha
        focusIndicatorView.transform = CGAffineTransform(scaleX: startScale, y: startScale)
        
        // 애니메이션: 크기 축소
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.focusIndicatorView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            if startAlpha < 1.0 {
                self.focusIndicatorView.alpha = 1.0
            }
        })
        // 초점 상태 관찰로 색상 변경 및 페이드 아웃은 observeFocusState에서 처리
    }
    
    private func fadeOutFocusIndicator() {
        // 페이드 아웃 애니메이션
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            self.focusIndicatorView.alpha = 0.0
        }, completion: { _ in
            self.focusIndicatorView.isHidden = true
            // 색상을 다시 흰색으로 리셋
            self.updateFocusIndicatorColor(.white)
        })
    }
}
