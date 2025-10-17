//
//  AuthView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI

struct AuthNumberView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: AuthNumberViewModel
    @StateObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(leadingType: .back(action: {
                coordinator.pop()
            }), centerType: .title(title: "본인인증"), trailingType: .none, navigationColor: .black)
            
            Spacer()
                .frame(height: 104)
            
            HStack {
                Text("문자")
                    .font(.titleBold20)
                +
                Text("로 받은\n")
                +
                Text("인증번호")
                    .font(.titleBold20)
                +
                Text("를 입력해 주세요")
                
                Spacer()
            }
            .lineSpacing(4)
            .font(.subtitleMedium20)
            .padding(.bottom, 32)
            
            CustomTextField(
                title: nil,
                placeholder: "인증번호를 입력해 주세요",
                text: $viewModel.verificationCode,
                keyboard: .numberPad,
                errorText: $viewModel.codeError
            )
            .padding(.bottom, 32)
            
            Spacer()
            
            CustomButton(title: "인증하기", isEnable: !viewModel.verificationCode.isEmpty && !viewModel.isLoading, action: viewModel.logIn, isProgressView: viewModel.isLoading)
        }
        .task {
            viewModel.attach(coordinator: coordinator)
        }
        .padding(.horizontal, 20)
        .backHiddenSwipeEnabled()
        .dismissKeyboard()
    }
}
