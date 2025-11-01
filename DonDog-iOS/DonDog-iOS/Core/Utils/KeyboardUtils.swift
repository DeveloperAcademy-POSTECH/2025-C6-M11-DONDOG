//
//  KeyboardUtils.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import Combine
import Foundation
import SwiftUI

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
