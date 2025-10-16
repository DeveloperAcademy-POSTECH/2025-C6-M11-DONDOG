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
        VStack(spacing: 0) {
            CustomNavigationBar(leadingType: viewModel.showSentHint ? .none : .back(action: coordinator.pop), centerType: .title(title: "가족 연결"), trailingType: .none, navigationColor: .black)
            
            HStack {
                Text("\(viewModel.userName ?? "") ")
                    .font(.titleBold20)
                + Text("님\n")
                + Text("이제 가족과 연결해 보세요")
                
                Spacer()
            }
            .font(.subtitleMedium20)
            .padding(.vertical, 40)
            
            // MARK: - 다른 사람 초대코드 입력
            CustomTextField(
                title: "가족에게 받은 초대 코드가 있어요",
                placeholder: "영어와 숫자 조합의 코드를 입력해 주세요",
                text: $viewModel.inputInviteCode,
                keyboard: .default,
                contentType: nil,
                errorMessage: viewModel.message
            )
            .padding(.bottom, 40)
            .disabled(viewModel.isLoading)
            
            // MARK: - 내 초대코드 띄우기
            VStack(alignment: .leading, spacing: 8) {
                Text("내 코드로 가족을 초대할게요")
                    .font(.subtitleMedium18)
                
                HStack(alignment: .top) {
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Text(viewModel.inviteText)
                                .font(.bodyRegular18)
                                .foregroundColor(viewModel.remainTimeText == "00:00" ? Color.ddGray500 : Color.ddBlack)
                            
                            Spacer()
                            
                            Text(viewModel.remainTimeText)
                                .font(.captionRegular13)
                                .foregroundStyle(Color.ddGray500)
                        }
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(Color.ddPrimaryBlue)
                    }
                    
                    if viewModel.remainTimeText == "00:00" {
                        ZStack {
                            RoundedRectangle(cornerRadius: 999)
                                .foregroundStyle(viewModel.isLoading ? Color.ddSecondaryBlue : Color.ddPrimaryBlue)
                                .frame(width: 70, height: 28)
                            
                            HStack(spacing: 2) {
                                Text("재발급")
                                Image(systemName: "arrow.trianglehead.counterclockwise")
                            }
                            .font(.captionRegular13)
                            .foregroundStyle(Color.ddWhite)
                        }
                        .onTapGesture {
                            if !viewModel.isLoading {
                                viewModel.refreshInviteCode()
                            }
                        }
                    } else {
                        ShareLink(
                            item: "https://앱스토어 링크",
                            message: Text("초대코드 \(viewModel.inviteText)를 입력하고 부모지를 시작하세요!")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18)
                                .foregroundStyle(Color.ddGray800)
                        }
                        .padding(.leading, 3)
                    }
                }
            }
            
            Spacer()
            
            CustomButton(title: "초대 코드 인증", isDisabled: !viewModel.inputInviteCode.isEmpty && !viewModel.isLoading, action: viewModel.connectWithInviteCode)
            
            if viewModel.showSentHint {
                Text("초대 코드를 보냈어요")
                    .foregroundStyle(Color.ddGray500)
                    .underline(true, pattern: .solid)
                    .font(.captionRegular13)
                    .onTapGesture {
                        coordinator.replaceRoot(.feed)
                    }
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .task { viewModel.fetchInviteCodeandExpireDate() }
        .onChange(of: viewModel.connectSucceeded) {
            coordinator.replaceRoot(.feed)
        }
    }
}
