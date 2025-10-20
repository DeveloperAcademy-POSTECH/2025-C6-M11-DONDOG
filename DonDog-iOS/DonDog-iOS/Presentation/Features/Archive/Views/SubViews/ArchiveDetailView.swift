//
//  ArchiveDetailView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/16/25.
//

import FirebaseAuth
import SwiftUI

struct ArchiveDetailView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ArchiveDetailViewModel
    
    @State private var currentIndex: Int = 0
    
    private var titleString: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.timeZone = TimeZone(identifier: "Asia/Seoul")
        fmt.dateFormat = "MM월 dd일"
        return fmt.string(from: viewModel.date)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // CustomNavigationBar
                CustomNavigationBar(
                    leadingType:
                            .back(
                                action: { coordinator.pop() }
                            ),
                    centerType:
                            .title(title: titleString),
                    trailingType: .menu(items: [
                        CustomNavMenuItem("삭제하기", role: .destructive) {
                            viewModel.handleDeleteRequest(at: currentIndex)
                        },
                    ]),
                    navigationColor: .black
                )
                .padding(.horizontal, 20)
                
                // 인디케이터
                CustomPageIndicator(
                    currentIndex: min(currentIndex + 1, max(viewModel.posts.count, 1)),
                    totalCount: max(viewModel.posts.count, 1),
                    backgroundColor: .ddGray100,
                    textColor: .ddGray500
                )
                .padding(.vertical, 4)
                
                // 캐러셀
                TabView(selection: $currentIndex) {
                    ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { idx, post in
                        DetailContentView(
                            post: post,
                            userNameByUid: viewModel.userNameByUid,
                            onDelete: { comment in
                                await viewModel.deleteComment(comment, from: post)
                            }
                        )
                        .tag(idx)
                    }
                }
                .frame(maxWidth: .infinity)
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // 캐러셀
            TabView(selection: $currentIndex) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { idx, post in
                    DetailContentView(
                        viewModel: ArchiveViewModel(roomId: viewModel.roomId), post: post,
                        userNameByUid: viewModel.userNameByUid,
                        onDelete: { comment in
                            await viewModel.deleteComment(comment, from: post)
            if viewModel.showUnauthorizedAlert {
                VStack {
                    Spacer()
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
        .background(.ddWhite)
        .backHiddenSwipeEnabled()
        .alert("사진을 삭제하시겠어요?", isPresented: $viewModel.showDeleteConfirmAlert) {
            Button("확인", role: .destructive) {
                Task {
                    let indexToDelete = currentIndex
                    await viewModel.deletePost(at: indexToDelete)
                    
                    // 삭제 후 새로고침
                    if !viewModel.posts.isEmpty && indexToDelete >= viewModel.posts.count {
                        currentIndex = viewModel.posts.count - 1
                    }
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("삭제한 사진은 되돌릴 수 없어요")
        }
    }
}
