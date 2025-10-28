//
//  PostDetailView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import SwiftUI
import FirebaseFirestore

struct PostDetailView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PostDetailViewModel
    @FocusState private var isTextFieldFocused: Bool
    @State private var currentIndex: Int = 0
    
    let postType: PostType
    
    var body: some View {
        CustomNavigationBar(
            leadingType:
                    .back(action: { coordinator.pop() }),
            centerType:
                .title(title: DateUtils.relativeTimeString(
                    from: (viewModel.posts.first?.createdAt.dateValue()) ?? Date(),
                    for: "MM월 dd일"
                )),
            trailingType: .menu(items: [
                CustomNavMenuItem("삭제하기", role: .destructive) {
                    if !viewModel.showUnauthorizedAlert {
                        viewModel.handleDeleteRequest(for: viewModel.posts[postType == .post ? 0 : currentIndex])
                    }
                },
            ]),
            navigationColor: .black
        )
        .padding(.horizontal, 20)
        .backHiddenSwipeEnabled()
        .alert("사진을 삭제하시겠어요?", isPresented: $viewModel.showDeleteConfirmAlert) {
            Button("확인", role: .cancel) {
                Task {
                    await viewModel.deletePost(for: viewModel.posts[postType == .post ? 0 : currentIndex])
                }
            }
            Button("취소", role: .destructive) { }
        } message: {
            Text("삭제한 사진은 되돌릴 수 없어요")
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onAppear {
            viewModel.checkIfItsMyPost(of: postType == .post ? 0 : currentIndex)
        }
        
        ZStack(alignment: .bottom) {
            viewFromPostOrArchive(postType: postType)
                .environmentObject(viewModel)
            
            if viewModel.showUnauthorizedAlert {
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
    
    @ViewBuilder
    private func viewFromPostOrArchive(postType: PostType) -> some View {
        if postType == .post {
            PostFromFeedView(isTextFieldFocused: $isTextFieldFocused)
        } else {
            PostFromArchiveView(currentIndex: $currentIndex)
        }
    }
}
