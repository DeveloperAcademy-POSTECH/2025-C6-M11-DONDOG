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
          HStack {
                HStack {
                    Text("초대코드")
                    Text(viewModel.inviteText)
                }
                
                Button {
                    UIPasteboard.general.string = viewModel.inviteText
                } label: {
                    Image(systemName: "document.on.document")
                }
                ShareLink(
                    item: "https://앱스토어 링크",
                    message: Text("초대코드 \(viewModel.inviteText)를 입력하고 부모지를 시작하세요!")
                ) {
                    Image(systemName: "square.and.arrow.up")
                    Text("초대하기")
                }
            }
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
