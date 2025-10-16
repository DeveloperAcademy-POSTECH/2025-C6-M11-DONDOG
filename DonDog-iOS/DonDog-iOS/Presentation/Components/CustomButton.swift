//
//  CustomButton.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import SwiftUI

struct CustomButton: View {
    var title: String
    var isDisabled: Bool = true
    var action: (() -> Void)?
    var isProgressView: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(isDisabled ? Color.ddPrimaryBlue : Color.ddSecondaryBlue)
            
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
        .frame(height: 52)
        .padding(.vertical, 8)
        .onTapGesture {
            if isDisabled {
                action?()
            }
        }
    }
}

#Preview {
    CustomButton(title: "Continue", isDisabled: true, action: { print("Disabled button tapped") })
    CustomButton(title: "Submit", isDisabled: false, action: { print("Enabled button tapped") }, isProgressView: true)
}
