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
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(isDisabled ? Color.ddPrimaryBlue : Color.ddSecondaryBlue)
            
            Text(title)
                .font(.subtitleMedium18)
                .foregroundStyle(Color.ddWhite)
        }
        .frame(height: 52)
        .onTapGesture {
            if !isDisabled {
                action?()
            }
        }
    }
}

#Preview {
    CustomButton(title: "Continue", isDisabled: true, action: { print("Disabled button tapped") })
    CustomButton(title: "Submit", isDisabled: false, action: { print("Enabled button tapped") })
}
