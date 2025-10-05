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
        VStack(spacing: 24) {
            Text("Profile Setup View")
                .font(.title)

            VStack(alignment: .leading, spacing: 12) {
                Text("이름/닉네임")
                    .font(.headline)
                TextField("이름/닉네임을 입력하세요", text: $viewModel.name)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("역할 (role)")
                    .font(.headline)
                Picker("역할", selection: $viewModel.selectedRole) {
                    ForEach(ProfileSetupViewModel.Role.allCases, id: \.self) { role in
                        Text(role.displayName).tag(role)
                    }
                }
                .pickerStyle(.segmented)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button(action: {
                viewModel.saveUserProfile()
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("확인 (Confirm)")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValid || viewModel.isLoading)
        }
        .padding(20)
        .onChange(of: viewModel.didComplete, initial: true) { oldValue, newValue in
            if newValue {
                coordinator.replaceRoot(.invite)
            }
        }
    }
}


