//
//  ProfileEditView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/9/25.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: EditProfileViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("프로필 수정")
                .font(.title)
            
            // 역할
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 24) {
                    CustomRolePicker(
                        selection: Binding<ProfileSetupViewModel.Role?>(
                            get: { viewModel.selectedRole },
                            set: { newValue in
                                if let role = newValue {
                                    viewModel.selectedRole = role
                                    viewModel.checkIfModified()
                                }
                            }
                        )
                    )
                }
            }
            
            // 닉네임
            VStack(alignment: .leading, spacing: 12) {
                Text("이름/닉네임")
                    .font(.headline)
                TextField("이름/닉네임을 입력하세요", text: $viewModel.name)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )
                    .onChange(of: viewModel.name) {
                        viewModel.checkIfModified()
                    }
            }
            
            // 에러 메시지
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            // 저장 버튼
            Button(action: {
                viewModel.saveChanges()
            }) {
                Text("저장 (Save)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValid || !viewModel.didChangeFromInitial)
        }
        .padding(20)
        .onAppear {
            viewModel.fetchCurrentProfile()
        }
        .onChange(of: viewModel.saveCompleted) { _, newValue in
            if newValue {
                coordinator.pop()
            }
        }
    }
}

#Preview {
    EditProfileView(viewModel: EditProfileViewModel())
}
