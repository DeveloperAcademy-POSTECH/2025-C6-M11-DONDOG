//
//  HapticUtils.swift
//  DonDog-iOS
//
//  Created by Ito on 10/23/25.
//

import UIKit

final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback (충격 피드백)
    
    /// 가벼운 충격 피드백 (버튼 탭 등)
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// 중간 충격 피드백
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 강한 충격 피드백
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// 부드러운 충격 피드백 (iOS 13+)
    func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// 딱딱한 충격 피드백 (iOS 13+)
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback (알림 피드백)
    
    /// 성공 알림 피드백
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 경고 알림 피드백
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// 에러 알림 피드백
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback (선택 피드백)
    
    /// 선택 변경 피드백 (피커, 토글 등)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Impact with Intensity
    
    /// 커스텀 강도의 충격 피드백 (iOS 13+)
    /// - Parameter intensity: 0.0 ~ 1.0 사이의 값
    func impact(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: intensity)
    }
}

// MARK: - Haptic Style Enum

enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case success
    case warning
    case error
    case selection
    
    func trigger() {
        switch self {
        case .light:
            HapticManager.shared.light()
        case .medium:
            HapticManager.shared.medium()
        case .heavy:
            HapticManager.shared.heavy()
        case .soft:
            HapticManager.shared.soft()
        case .rigid:
            HapticManager.shared.rigid()
        case .success:
            HapticManager.shared.success()
        case .warning:
            HapticManager.shared.warning()
        case .error:
            HapticManager.shared.error()
        case .selection:
            HapticManager.shared.selection()
        }
    }
}
