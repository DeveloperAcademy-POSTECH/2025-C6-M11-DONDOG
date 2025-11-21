import FirebaseFirestore
import Kingfisher
import SwiftUI

struct PostView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PostViewModel
    @StateObject var stickerViewModel = StickerViewModel()
    
    @State private var showDeleteConfirmAlert: Bool = false
    @State private var showStickerSheet = false
    @State private var isFrontOrBack: Int = 0
    @State private var isZooming: Bool = false
    @State private var isShowDetail: Bool = false
    
    let postType: PostType
    
    var body: some View {
        let createdAt = viewModel.post.createdAt.dateValue()
        
        ZoomContainer {
            ZStack {
                VStack {
                    if !isShowDetail {
                        CustomNavigationBar(
                            leadingType: .back(action: { coordinator.pop() }),
                            centerType: .timeTitle(title: "\(viewModel.postOwnerNickname)의 \(DateUtils.isATime(date: createdAt) ? "오전" : "오후")", timeImage: DateUtils.isATime(date: createdAt) ? "sun.max.fill" : "moon.fill"),
                            trailingType: viewModel.isMyPost ? .menu(items: [CustomNavMenuItem("삭제하기", role: .destructive) { showDeleteConfirmAlert = true }]) : .none,
                            navigationColor: .black
                        )
                        .padding(.horizontal, 20)
                        .backHiddenSwipeEnabled()
                    } else {
                        CustomNavigationBar(leadingType: .none, centerType: .none, trailingType: .close(action: { isShowDetail = false }), navigationColor: .white)
                            .padding(.horizontal, 20)
                    }
                    PostContentsView(post: viewModel.post, isEditing: $showStickerSheet, viewModel: stickerViewModel, isFrontOrBack: $isFrontOrBack, isZooming: $isZooming, isShowDetail: $isShowDetail)
                        .onTapGesture {
                            isShowDetail = true
                        }
                    
                    Spacer()
                }
                .customAlert(
                    isPresented: $showDeleteConfirmAlert,
                    title: "정말 삭제하시겠어요?",
                    message: "한 번 삭제한 게시물은 되돌릴 수 없어요",
                    confirmTitle: "삭제하기",
                    cancelTitle: "취소",
                    onConfirm: {
                        Task {
                            await viewModel.deletePost()
                            coordinator.pop()
                        }
                    },
                    onCancel: {    }
                )
            }
        }
        .background {
            if !isShowDetail {
                Color.ppWhite
                    .ignoresSafeArea()
            } else {
                Color.ppRealBlack
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut, value: isShowDetail)
        .navigationBarBackButtonHidden(true)
        .task {
            stickerViewModel.postId = viewModel.post.postId
            await stickerViewModel.fetchStickers()
        }
    }
}
