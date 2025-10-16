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
    
    @StateObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(leadingType: .back(action: {
                
                //:: 추후 수정 디자인피드백4
                !viewModel.isCodeSent ? coordinator.pop() : print("백이 아니라 iscodesent 취소되도록 수정")
                
            }), centerType: .title(title: "본인인증"), trailingType: .none, navigationColor: .black)
            
            Spacer()
                .frame(height: 104)
            
            Group {
                if viewModel.isCodeSent {
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
                } else {
                    HStack {
                        Text("윙키")
                            .font(.titleBold20)
                        +
                        Text("를 이용하기 위해\n")
                        +
                        Text("전화번호")
                            .font(.titleBold20)
                        +
                        Text("를 이용한 인증이 필요해요")
                        
                        Spacer()
                    }
                }
            }
            .lineSpacing(4)
            .font(.subtitleMedium20)
            .padding(.bottom, 32)

            CustomTextField(
                title: nil,
                prefix: "+82",
                placeholder: "10-1234-5678",
                text: $viewModel.userPhoneNumber,
                keyboard: .numberPad,
                contentType: .telephoneNumber,
                errorMessage: viewModel.phoneError
            )
            .padding(.bottom, 32)
            
            if viewModel.isCodeSent {
                CustomTextField(
                    title: nil,
                    prefix: nil,
                    placeholder: "인증번호를 입력해 주세요",
                    text: $viewModel.verificationCode,
                    keyboard: .numberPad,
                    errorMessage: viewModel.codeError
                )
                .padding(.bottom, 32)
            }
            
            Spacer()
            
            VStack {
                Text("익명 로그인(개발자용)")
                    .font(.title)
                
                Button(action: viewModel.signInAnonymously) {
                    Text("익명 로그인 시작")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .border(Color.red, width: 3)
            
            Spacer()
            
            Group {
                if viewModel.isCodeSent {
                    CustomButton(title: "인증하기", isDisabled: !viewModel.verificationCode.isEmpty && !viewModel.isLoading, action: viewModel.logIn)
                } else {
                    CustomButton(title: "다음", isDisabled: !viewModel.userPhoneNumber.isEmpty && !viewModel.isLoading, action: viewModel.sendCode)
                }
            }
            .padding(.bottom, keyboard.keyboardHeight == 0 ? 0 : 10)

        }
        .padding(.horizontal, 20)
        .backHiddenSwipeEnabled()
        .dismissKeyboard()
        .task {
            viewModel.attach(coordinator: coordinator)
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel())
}
