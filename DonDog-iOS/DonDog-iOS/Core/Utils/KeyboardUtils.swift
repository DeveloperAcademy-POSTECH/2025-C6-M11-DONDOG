//
//  KeyboardUtils.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import Foundation
import SwiftUI
import Combine

extension View {
    /// 텍스트 입력 중 화면을 탭하면 키보드를 내리는 커스텀 Modifier
    func dismissKeyboard() -> some View {
            self
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }
                )
        }
}

final class KeyboardResponder: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 키보드 나타날 때
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .sink { [weak self] height in self?.keyboardHeight = height }
            .store(in: &cancellables)

        // 키보드 사라질 때
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .sink { [weak self] height in self?.keyboardHeight = height }
            .store(in: &cancellables)
    }
}
