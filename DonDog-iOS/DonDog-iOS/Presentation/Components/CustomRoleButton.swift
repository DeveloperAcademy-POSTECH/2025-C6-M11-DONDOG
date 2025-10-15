//
//  CustomRolePicker.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import SwiftUI

struct CustomRolePicker: View {
    @Binding var selection: ProfileSetupViewModel.Role?
    
    private func isSelected(_ role: ProfileSetupViewModel.Role) -> Bool {
        selection == .some(role)
    }
    
    var body: some View {
        HStack(spacing: 56) {
            ForEach(ProfileSetupViewModel.Role.allCases, id: \.self) { role in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isSelected(role) ? Color.ddPrimaryBlue : Color.ddGray100, lineWidth: 4
                            )
                            .frame(width: 120, height: 120)
                        
                        Text(role.displayIcon)
                            .font(.custom(FontName.pretendardBold.rawValue, size: 48))
                    }
                    .contentShape(Circle())
                    .onTapGesture { selection = role }
                    
                    Text(role.displayName)
                        .font(isSelected(role) ? .titleBold18 : .bodyRegular18)
                        .foregroundStyle(isSelected(role) ? Color.ddPrimaryBlue: Color.ddBlack)
                }
                .accessibilityLabel(Text(role.displayName))
                .accessibilityAddTraits(isSelected(role) ? .isSelected : [])
            }
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedRole: ProfileSetupViewModel.Role? = nil
        
        var body: some View {
            CustomRolePicker(selection: $selectedRole)
        }
    }

    return PreviewWrapper()
}
