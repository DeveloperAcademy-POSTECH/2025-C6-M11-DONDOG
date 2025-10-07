//
//  InviteView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI

struct InviteView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: InviteViewModel
    
    var body: some View {
        VStack {
            Text("Invite View")
                .font(.title)
        
            // MARK: - 내 초대코드 띄우기
            Text(viewModel.inviteText)
                .font(.title2)
            Text(viewModel.remainTimeText)
                .foregroundColor(.secondary)
            
            Text("초대코드 입력")
                .font(.title2)
            
            // MARK: - 다른 사람 초대코드 입력
            TextField("다른 사람의 초대코드", text: $viewModel.inputInviteCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("확인") {
                viewModel.connectWithInviteCode()
            }

            if !viewModel.connectMessage.isEmpty {
                Text(viewModel.connectMessage)
                    .foregroundStyle(viewModel.connectSucceeded ? .green : .red)
            }
            
            // MARK: - 네비게이션
            Button("feed로 이동") {
                coordinator.replaceRoot(.feed)
            }
            
        }
        .task { viewModel.fetchInviteCodeandExpireDate() }
        .onChange(of: viewModel.connectSucceeded) {
            coordinator.replaceRoot(.feed)
        }
    }
}

#Preview {
    InviteView(viewModel: InviteViewModel())
}
