//
//  CustomButton.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import SwiftUI

struct CustomButton: View {
    var title: String
    var isEnable: Bool = true
    var action: (() -> Void)?
    var isProgressView: Bool = false
    @StateObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(isEnable ? Color.ddPrimaryBlue : Color.ddSecondaryBlue)
            
            HStack(spacing: 8) {
                Text(title)
                    .font(.subtitleMedium18)
                    .foregroundStyle(Color.ddWhite)
                if isProgressView {
                    ProgressView()
                        .frame(width: 16, height: 16)
                        .tint(Color.ddWhite50)
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
}

#Preview {
    CustomButton(title: "Continue", isEnable: true, action: { print("Disabled button tapped") })
    CustomButton(title: "Submit", isEnable: false, action: { print("Enabled button tapped") }, isProgressView: true)
}
