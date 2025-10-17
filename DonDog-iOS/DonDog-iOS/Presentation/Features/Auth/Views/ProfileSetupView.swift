//
//  ProfileSetupView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/4/25.
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ProfileSetupViewModel
    @StateObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(leadingType: .none, centerType: .title(title: "프로필 설정"), trailingType: .none, navigationColor: .black)
            
            HStack {
                Text("부모님과 자녀 ")
                + Text("둘만의 소통")
                    .font(.titleBold20)
                + Text("을 위해\n")
                + Text("별명과 역할")
                    .font(.titleBold20)
                + Text("을 설정해 주세요")
                
                Spacer()
            }
            .font(.subtitleMedium20)
            .padding(.vertical, 32)
            
            CustomRolePicker(selection: $viewModel.selectedRole)
                .padding(.bottom, 26)
            
            CustomTextField(
                title: nil,
                placeholder: "불리고 싶은 별명을 입력해 주세요",
                text: $viewModel.name,
                keyboard: .default,
                contentType: nil,
                errorMessage: viewModel.errorMessage,
                softMaxLength: 10,
                softMaxErrorText: "최대 10자까지 입력할 수 있어요"
            )
            
            Spacer()
            
            CustomButton(
                title: "다음",
                isEnable: viewModel.isValid && viewModel.name.count < 10,
                action: viewModel.saveUserProfile
            )
        }
        .padding(.horizontal, 20)
        .dismissKeyboard()
        .backHiddenSwipeEnabled()
        .onChange(of: viewModel.didComplete, initial: true) { _, newValue in
            if newValue {
                coordinator.inviteShowSentHint = true
                coordinator.replaceRoot(.invite)
            }
        }
    }
}

#Preview {
    ProfileSetupView(viewModel: ProfileSetupViewModel())
}
