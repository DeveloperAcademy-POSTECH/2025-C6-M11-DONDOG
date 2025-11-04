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
        ZStack {
            LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(0.35)
            
            VStack(spacing: 0) {
                CustomNavigationBar(leadingType: .back(action: { coordinator.pop() }), centerType: .title(title: "설정", timeImage: ""), trailingType: .none, navigationColor: .black)
                
                HStack {
                    VStack(alignment: .leading, spacing: 24) {
                        Button { coordinator.push(.editprofile) }    label: { Text("프로필 수정") }
                        Button { viewModel.showLogoutConfirm = true } label: { Text("로그아웃") }
                        Button { viewModel.showDeleteConfirm = true } label: { Text("회원탈퇴") }
                        
                        Button {
                            if let url = URL(string: "https://posacademy.notion.site/Winky-2922b843d5af8058aabbc9bbe3009139?source=copy_link") {
                                webSheet = WebSheetItem(url: url)
                            }
                        } label: {
                            Text("개인정보처리방침")
                        }
                        .foregroundStyle(Color.ddGray500)

                        Button {
                            if let url = URL(string: "https://posacademy.notion.site/2932b843d5af8002a16df56cb9d27afe?source=copy_link") {
                                webSheet = WebSheetItem(url: url)
                            }
                        } label: {
                            Text("신고하기")
                        }
                        .foregroundStyle(Color.ddGray500)

                    }
                    .font(.subtitleMedium18)
                    .foregroundStyle(Color.ddGray1000)
        
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 35)
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarBackButtonHidden(true)
            .alert("", isPresented: $viewModel.showLogoutConfirm) {
                Button("취소", role: .cancel) {}
                Button("로그아웃", role: .destructive) {
                    Task { await viewModel.logout() }
                }
            } message: {
                Text("로그아웃 하시겠습니까?")
            }
            .alert("윙키를 탈퇴하시겠습니까?", isPresented: $viewModel.showDeleteConfirm) {
                Button("취소", role: .cancel) {}
                Button("확인", role: .destructive) {
                    coordinator.authShowWithdraw = true
                    coordinator.push(.auth)
                }
            } message: {
                Text("탈퇴하면 모든 기록이 사라져요")
            }
        }
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
