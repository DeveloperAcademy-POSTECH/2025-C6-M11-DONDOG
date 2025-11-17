//
//  CameraViewController+Sticker.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/16/25.
//

import AVFoundation
import SwiftUI
import UIKit

extension CustomCameraViewController {
    func configureModeFromEmotionTags() {
        let tags = StickerEmotionTagManager.shared.emotionTags
        
        if tags.count >= 2 {
            isStickerCamera = true
            stickerKeyword = tags[1]
        } else {
            isStickerCamera = false
            stickerKeyword = nil
        }
    }
    
    // TODO: 삭제 예정
    func showStickerMaskOverlay() {
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        if stickerMaskView.superview != nil { return }
        
        stickerMaskView.backgroundColor = UIColor.ppRealBlack.withAlphaComponent(0.7)
        stickerMaskView.translatesAutoresizingMaskIntoConstraints = false
        stickerMaskView.isUserInteractionEnabled = false
        view.addSubview(stickerMaskView)
        
        /// 마스크는 전체 뷰를 덮되, 상단 가이드는 그 위에 보이도록 레이어 조정
        if stickerGuideContainer.superview != nil {
            view.bringSubviewToFront(stickerGuideContainer)
        }
        view.bringSubviewToFront(cancelButton)
        
        NSLayoutConstraint.activate([
            stickerMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            stickerMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stickerMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickerMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        view.layoutIfNeeded()
        updateStickerMaskPath()
        
        /// 딤드 - 카메라뷰 전환 직후 보이게
        stickerMaskView.alpha = 1.0
        
        /// 딤드 - 0.8초 동안 유지 후 0.4초 동안 easeOut으로 사라지기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            /// 마스크가 표시되는 동안 스티커 서브타이틀 더 옅은 색으로 표시
            self.stickerSubtitleLabel.textColor = .ppGray200
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                options: .curveEaseOut,
                animations: {
                    /// 페이드아웃이 시작될 때 바로 진한 색으로 변경
                    self.stickerSubtitleLabel.textColor = .ppGray700
                    self.stickerMaskView.alpha = 0.0
                },
                completion: { _ in
                    self.stickerMaskView.removeFromSuperview()
                }
            )
        }
    }
    
    func setupStickerGuide() {
        guard isStickerCamera else { return }
        let tagText = stickerKeyword ?? StickerEmotionTagManager.shared.emotionTags.last ?? ""
        
        stickerGuideContainer.axis = .vertical
        stickerGuideContainer.alignment = .center
        stickerGuideContainer.distribution = .fill
        stickerGuideContainer.spacing = 4
        
        stickerTitleLabel.text = tagText
        stickerTitleLabel.font = UIFont(name: FontName.sejongGeulggot.rawValue, size: 32) ?? UIFont.systemFont(ofSize: 32, weight: .bold)
        stickerTitleLabel.textColor = .ppPrime
        stickerTitleLabel.textAlignment = .center
        
        stickerSubtitleLabel.text = "스티커에 어울리는 사진을 찍어주세요"
        stickerSubtitleLabel.font = UIFont(name: FontName.pretendardRegular.rawValue, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .regular)
        stickerSubtitleLabel.textColor = .ppGray300
        stickerSubtitleLabel.textAlignment = .center
        
        stickerGuideContainer.addArrangedSubview(stickerTitleLabel)
        stickerGuideContainer.addArrangedSubview(stickerSubtitleLabel)
        
        view.addSubview(stickerGuideContainer)
        stickerGuideContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stickerGuideContainer.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 24),
            stickerGuideContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stickerGuideContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func updateStickerMaskPath() {
        let bounds = stickerMaskView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        let path = UIBezierPath(rect: bounds)
        
        let ellipseWidth: CGFloat = 300
        let ellipseHeight: CGFloat = 350
        let ellipseRect = CGRect(
            x: (bounds.width - ellipseWidth) / 2,
            y: (bounds.height - ellipseHeight) / 2,
            width: ellipseWidth,
            height: ellipseHeight
        )
        
        let holePath = UIBezierPath(ovalIn: ellipseRect)
        path.append(holePath)
        
        stickerMaskLayer.path = path.cgPath
        stickerMaskLayer.fillRule = .evenOdd   /// 구멍 만들기
        stickerMaskView.layer.mask = stickerMaskLayer
    }
}
