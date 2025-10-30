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
    @StateObject private var keyboard = KeyboardResponder()
    
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
            
            CustomTextField(
                title: "가족에게 받은 초대 코드가 있어요",
                placeholder: "영어와 숫자 조합의 코드를 입력해 주세요",
                text: $viewModel.inputInviteCode,
                keyboard: .default,
                contentType: nil,
                errorMessage: viewModel.message,
                showExternalError: $viewModel.allowInviteCodeError
            )
            .padding(.bottom, 40)
            .disabled(viewModel.isLoading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("내 코드로 가족을 초대할게요")
                    .font(.subtitleMedium18)
                
                HStack(alignment: .top) {
                    VStack(spacing: 4) {
                        if !viewModel.inviteText.isEmpty {
                            HStack(spacing: 0) {
                                Text(viewModel.inviteText)
                                    .font(.bodyRegular18)
                                    .foregroundColor(viewModel.remainTimeText == "00:00" ? Color.ddGray500 : Color.ddBlack)
                                
                                Spacer()
                                
                                Text(viewModel.remainTimeText)
                                    .font(.captionRegular13)
                                    .foregroundStyle(Color.ddGray500)
                            }
                        } else {
                            Text("Wingky")
                                .font(.bodyRegular18)
                                .opacity(0)
                        }
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(Color.ddPrimaryBlue)
                    }
                    
                    if viewModel.remainTimeText == "00:00" || viewModel.inviteText == "초대코드를 불러오지 못했습니다." {
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
                            item: "https://testflight.apple.com/join/4QzRhxBT",
                            message: Text("\n🪽 윙키 초대장이 도착했어요!\n사진 한 장으로 멀리 떨어져 있어도, 특별한 추억을 쌓아요.\n\n초대코드 : \(viewModel.inviteText)")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18)
                                .foregroundStyle(Color.ddGray800)
                                .padding(.leading, 3)
                        }
                    }
                }
            }
            
            Spacer()
            
            CustomButton(title: "연결하기", isEnable: !viewModel.inputInviteCode.isEmpty && !viewModel.isLoading, action: viewModel.connectWithInviteCode)
                .padding(.bottom, viewModel.showSentHint ? (keyboard.keyboardHeight == 0 ? 0 : -10) : 0)
            
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
        .backHiddenSwipeEnabled()
        .dismissKeyboard()
        .task { viewModel.fetchInviteCodeandExpireDate() }
    }
}
