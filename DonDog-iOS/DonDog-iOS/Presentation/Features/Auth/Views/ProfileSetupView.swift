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
                errorMessage: viewModel.errorMessage
            )
            
            Spacer()
            
            CustomButton(title: "다음", isDisabled: viewModel.isValid, action: viewModel.saveUserProfile)
        }
        .padding(20)
        .navigationBarBackButtonHidden(true)
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
