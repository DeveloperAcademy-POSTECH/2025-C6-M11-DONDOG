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
    struct WebSheetItem: Identifiable { let id = UUID(); let url: URL }
    @State private var webSheet: WebSheetItem?
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(leadingType: .back(action: { coordinator.pop() }), centerType: .title(title: "설정"), trailingType: .none, navigationColor: .black)
                .padding(.horizontal, 16)
            
            HStack {
                VStack(alignment: .leading, spacing: 24) {
                    Button { coordinator.push(.editprofile) }    label: { Text("프로필 수정").font(.subtitleMedium18).foregroundStyle(Color.ppGray700) }
                    Button { viewModel.showLogoutConfirm = true } label: { Text("로그아웃").font(.subtitleMedium18).foregroundStyle(Color.ppGray700) }
                    Button { viewModel.showDeleteConfirm = true } label: { Text("회원탈퇴").font(.subtitleMedium18).foregroundStyle(Color.ppGray700) }
                    
                    Button {
                        if let url = URL(string: "https://posacademy.notion.site/Winky-2922b843d5af8058aabbc9bbe3009139?source=copy_link") {
                            webSheet = WebSheetItem(url: url)
                        }
                    } label: {
                        Text("개인정보처리방침")
                    }
                    .foregroundStyle(Color.ppGray400)
                    
                    Button {
                        if let url = URL(string: "https://posacademy.notion.site/2932b843d5af8002a16df56cb9d27afe?source=copy_link") {
                            webSheet = WebSheetItem(url: url)
                        }
                    } label: {
                        Text("신고하기")
                    }
                    .foregroundStyle(Color.ppGray400)
                    
                }
                .font(.subtitleMedium18)
                .foregroundStyle(Color.ppGray700)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            Spacer()
        }
        .background(.ppWhite)
        .navigationBarBackButtonHidden(true)
        .customAlert(
            isPresented: $viewModel.showLogoutConfirm,
            title: "로그아웃 하시겠어요?",
            confirmTitle: "로그아웃",
            cancelTitle: "취소",
            onConfirm: {
                Task { await viewModel.logout() }
            },
            onCancel: {
                //
            }
        )
        .customAlert(
            isPresented: $viewModel.showDeleteConfirm,
            title: "회원을 탈퇴하시겠어요?",
            message: "탈퇴하면 모든 기록이 사라져요",
            confirmTitle: "탈퇴하기",
            cancelTitle: "취소",
            onConfirm: {
                coordinator.authShowWithdraw = true
                coordinator.push(.auth)
            },
            onCancel: {
                //
            }
        )
        .sheet(item: $webSheet) { item in
            InAppWebSheet(url: item.url)
                .ignoresSafeArea()
        }
        .backHiddenSwipeEnabled()
    }
}

#Preview {
    SettingView(viewModel: SettingViewModel())
}
