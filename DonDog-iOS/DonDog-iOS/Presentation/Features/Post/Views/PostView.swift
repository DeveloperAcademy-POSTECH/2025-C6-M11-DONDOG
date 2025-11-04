//
//  PostView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import FirebaseFirestore
import SwiftUI

struct PostView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PostViewModel
    @State private var currentIndex: Int = 0
    
    let postType: PostType
    
    var body: some View {
        CustomNavigationBar(
            leadingType: .back(action: { coordinator.pop() }),
            centerType: .title(title: DateUtils.string(from: (viewModel.posts.first?.createdAt.dateValue()) ?? Date(), format: .monthDay), timeImage: DateUtils.isATime() ? "sun.max" : "moon.fill"),
            trailingType: .menu(items: [
                CustomNavMenuItem("삭제하기", role: .destructive) {
                    viewModel.checkIfItsMyPost(of: postType == .post ? 0 : currentIndex)
                    
                    if !viewModel.showUnauthorizedAlert {
                        viewModel.handleDeleteRequest(for: viewModel.posts[postType == .post ? 0 : currentIndex])
                    }
                }
            ]),
            navigationColor: .black
        )
        .padding(.horizontal, 20)
        .backHiddenSwipeEnabled()
        .alert("사진을 삭제하시겠어요?", isPresented: $viewModel.showDeleteConfirmAlert) {
            Button("확인", role: .cancel) {
                Task {
                    await viewModel.deletePost(for: viewModel.posts[currentIndex])
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if postType == .post {
                            coordinator.pop()
                        } else {
                            if currentIndex > 0 {
                                currentIndex -= 1
                            } else if viewModel.posts.count > 1 {
                                currentIndex = 0
                            } else {
                                coordinator.pop()
                            }
                        }
                    }
                }
            }
            
            Button("취소", role: .destructive) { }
        } message: {
            Text("삭제한 사진은 되돌릴 수 없어요")
        }
        
        ZStack(alignment: .bottom) {
            PostFrameView(currentIndex: $currentIndex, viewModel: viewModel, postType: postType)
            
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
}
