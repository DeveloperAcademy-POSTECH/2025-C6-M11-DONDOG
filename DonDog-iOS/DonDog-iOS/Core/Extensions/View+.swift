//
//  View+.swift
//  DonDog-iOS
//
//  Created by 조유진 on 11/1/25.
//

import SwiftUI

extension View {
    /// 버튼 탭 시 햅틱 피드백 추가
    func hapticFeedback(_ style: HapticStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                style.trigger()
            }
        )
    }
    
    /// 텍스트 입력 중 화면을 탭하면 키보드 내리기
    func dismissKeyboard() -> some View {
        self
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            })
    }
    
    /// 네비게이션 백버튼 숨기기
    func backHiddenSwipeEnabled() -> some View {
        self.modifier(BackHiddenSwipeEnabled())
    }
}
