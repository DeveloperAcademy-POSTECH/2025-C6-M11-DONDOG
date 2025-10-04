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
    
    var body: some View {
        VStack(spacing: 20) {
            Text("익명 로그인(개발자용)")
                .font(.title)
                .padding(.top, 40)
            
            Button(action: viewModel.signInAnonymously) {
                Text("익명 로그인 시작")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 32)
            
            Text("전화번호 로그인")
                .font(.title)
                .padding(.top, 40)

            TextField("전화번호 (01012345678 형식)", text: $viewModel.userPhoneNumber)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // 디버깅 - 추후 삭제 예정
            VStack(alignment: .leading, spacing: 6) {
                Text("서버 전송 번호 (디버깅용)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text(viewModel.serverPhoneNumber.isEmpty ? "(미입력)" : viewModel.serverPhoneNumber)
                        .font(.callout)
                        .foregroundColor(viewModel.serverPhoneNumber.isEmpty ? .secondary : .blue)
                    Spacer()
                }
            }
            
            if viewModel.isCodeSent {
                TextField("SMS 인증번호", text: $viewModel.verificationCode)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if !viewModel.isCodeSent {
                Button(action: viewModel.sendCode) {
                    Text("인증번호 요청")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Button(action: viewModel.logIn) {
                    Text("로그인")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 32)
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
            
            Text(viewModel.message)
                .foregroundColor(.red)
                .padding()
            
            if viewModel.isLoggedIn {
                Text("로그인 성공! 🎉").foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 20)
        .task {
            viewModel.attach(coordinator: coordinator)
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel())
}
