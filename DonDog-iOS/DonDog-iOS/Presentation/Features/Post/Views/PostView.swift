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
    
    @State private var showStickerSheet = false
    
    let postType: PostType
    
    var body: some View {
        let createdAt = viewModel.post.createdAt.dateValue()
        CustomNavigationBar(
            leadingType: .back(action: { coordinator.pop() }),
            centerType: .timeTitle(title: DateUtils.string(from: createdAt, format: .monthDay), timeImage: DateUtils.isATime(date: createdAt) ? "sun.max" : "moon.fill"),
            trailingType: .menu(items: [
                CustomNavMenuItem("삭제하기", role: .destructive) {
                    if !viewModel.showUnauthorizedAlert {
                        viewModel.handleDeleteRequest(for: viewModel.post)
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
                    await viewModel.deletePost(for: viewModel.post)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        coordinator.pop()
                    }
                }
            }
            
            Button("취소", role: .destructive) { }
        } message: {
            Text("삭제한 사진은 되돌릴 수 없어요")
        }
        
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PostContentsView(post: viewModel.post, isEditing: $showStickerSheet)
                
                Spacer()
                
                if postType == .post {
                    CustomButton(title: "스티커 붙이기", isEnable: true, action: { showStickerSheet = true })
                        .padding(.horizontal, 20)
                }
            }
            
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
        .sheet(isPresented: $showStickerSheet) {
            StickerSheetView()
            .presentationDetents([.height(270)])
            .presentationDragIndicator(.hidden)
            .background(Color.ddGray100.opacity(0.5))
        }
    }
}
