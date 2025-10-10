//
//  SettingView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/8/25.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: SettingViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    coordinator.push(.editprofile)
                } label: {
                    Text("프로필 수정")
                }
                
                Button {
                    viewModel.logout()
                } label: {
                    Text("로그아웃")
                }
                
                Button {
                    viewModel.showDeleteConfirm = true
                } label: {
                    Text("회원탈퇴")
                }
                
                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .alert("회원탈퇴", isPresented: $viewModel.showDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                viewModel.performAccountDeletion()
            }
        } message: {
            Text("정말로 계정을 완전히 삭제할까요? 이 작업은 되돌릴 수 없습니다.")
        }
    }
}

#Preview {
    SettingView(viewModel: SettingViewModel())
}
