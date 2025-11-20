//
//  CustomButton.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import SwiftUI

enum CustomButtonStyleType {
    case primary
    case secondary // 취소 자리 - 회색 버튼
}

struct CustomButton: View {
    var title: String
    var style: CustomButtonStyleType = .primary
    var isEnable: Bool = true
    var action: (() -> Void)?
    var isProgressView: Bool = false
    @StateObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(backgroundColor)
            
            HStack(spacing: 8) {
                if title == "다시 촬영하기" {
                    Image(systemName: "arrow.trianglehead.clockwise")
                        .foregroundStyle(Color.ppWhite)
                        .font(.system(size: 22))
                        .padding(.leading, 2)
                }
                Text(title)
                    .font(.bodyMedium16)
                    .foregroundStyle(Color.ppWhite)
                if isProgressView {
                    ProgressView()
                        .frame(width: 16, height: 16)
                        .tint(Color.ppWhite)
                }
            }
        }
        .disabled(!isEnable)
        .frame(height: 52)
        .padding(.vertical, 8)
        .onTapGesture {
            if isEnable {
                action?()
            }
        }
        .padding(.bottom, keyboard.keyboardHeight == 0 ? 0 : 10)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isEnable ? Color.ppPrime : Color.ppPrime50
        case .secondary:
            return Color.ppGray400
        }
    }
}

#Preview {
    CustomButton(title: "Continue", style: .primary, isEnable: true, action: { print("Disabled button tapped") })
    CustomButton(title: "Continue", style: .secondary, isEnable: true, action: { print("Disabled button tapped") })
    CustomButton(title: "Submit", isEnable: false, action: { print("Enabled button tapped") }, isProgressView: true)
}
