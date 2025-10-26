//
//  PostDetailView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import SwiftUI

struct PostDetailView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PostDetailViewModel
    
    var body: some View {
        CustomNavigationBar(
            leadingType:
                    .back(action: { coordinator.pop() }),
            centerType:
                // TODO: Date() 대신 해당 post 작성 날짜 넣기
                    .title(title: DateUtils.relativeTimeString(from: Date(), for: "MM월 dd일")),
            trailingType: .menu(items: [
                CustomNavMenuItem("삭제하기", role: .destructive) {
                    viewModel.handleDeleteRequest()
                },
            ]),
            navigationColor: .black
        )
        .padding(.horizontal, 20)
        .backHiddenSwipeEnabled()
        .alert("사진을 삭제하시겠어요?", isPresented: $viewModel.showDeleteConfirmAlert) {
            Button("확인", role: .cancel) {
                Task {
                    await viewModel.deletePost()
                }
            }
            Button("취소", role: .destructive) { }
        } message: {
            Text("삭제한 사진은 되돌릴 수 없어요")
        }
        
        ZStack(alignment: .bottom) {
            // post 메인 컨텐츠 뷰
            
            ToastView(toastText: "본인이 작성한 글만 삭제할 수 있어요")
                .padding(.bottom, 80)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            viewModel.showUnauthorizedAlert = false
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).animation(.spring()),
                    removal: .opacity.animation(.easeOut(duration: 0.7))
                ))
        }
    }
}
