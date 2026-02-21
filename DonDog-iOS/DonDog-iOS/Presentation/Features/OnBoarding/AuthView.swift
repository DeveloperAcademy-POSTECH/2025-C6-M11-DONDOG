//
//  AuthView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: AuthViewModel
    @AppStorage("hasSeenInitialOnboarding") var hasSeenInitialOnboarding: Bool = false
    
    var body: some View {
        if hasSeenInitialOnboarding == false && !viewModel.isWithDraw {
            InitialOnBoardingView()
        } else {
            VStack(spacing: 0) {
                CustomNavigationBar(leadingType: .back(action: {coordinator.pop()}), centerType: .title(title: "본인인증"), trailingType: .none, navigationColor: .black)
                
                Spacer()
                    .frame(height: 104)
                
                HStack {
                    if viewModel.isWithDraw {
                        Text("픽픽")
                            .font(.titleBold20)
                        +
                        Text("을 탈퇴하기 위해\n")
                        +
                        Text("전화번호")
                            .font(.titleBold20)
                        +
                        Text("를 이용한 인증이 필요해요")
                    } else {
                        Text("픽픽")
                            .font(.titleBold20)
                        +
                        Text("을 이용하기 위해\n")
                        +
                        Text("전화번호")
                            .font(.titleBold20)
                        +
                        Text("를 이용한 인증이 필요해요")
                    }
                    
                    Spacer()
                }
                .lineSpacing(4)
                .font(.subtitleMedium20)
                .padding(.bottom, 32)
                
                CustomTextField(
                    title: nil,
                    placeholder: "010-1234-5678",
                    text: $viewModel.userPhoneNumber,
                    keyboard: .numberPad,
                    contentType: .telephoneNumber,
                    errorText: $viewModel.phoneError,
                    isDisabled: viewModel.isLoading
                )
                .padding(.bottom, 32)
                
                Spacer()
                
                CustomButton(title: "다음", isEnable: !viewModel.userPhoneNumber.isEmpty && !viewModel.isLoading, action: viewModel.sendCode, isProgressView: viewModel.isLoading)
                
            }
            .padding(.horizontal, 20)
            .background(.ppWhite)
            .task {
                viewModel.attach(coordinator: coordinator)
            }
            .backHiddenSwipeEnabled()
            .dismissKeyboard()
            .customAlert(
                isPresented: $viewModel.showPhoneMismatchAlert,
                title: "가입한 전화번호가 아니에요",
                message: "번호를 다시 확인해 주세요",
                confirmTitle: "확인",
                onConfirm: {
                    // 삭제 로직
                }
            )
        }
    }
}
