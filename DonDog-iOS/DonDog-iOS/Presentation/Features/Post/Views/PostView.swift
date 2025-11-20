//
//  PostView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import FirebaseFirestore
import Kingfisher
import SwiftUI

struct PostView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PostViewModel
    @StateObject var stickerViewModel = StickerViewModel()
    
    @State private var showDeleteConfirmAlert: Bool = false
    @State private var showStickerSheet = false
    
    @State private var showImageDetail = false
    @State private var isFrontOrBack: Int = 0
    
    @State private var scale: CGFloat = 1.0
    @GestureState private var pinchScale: CGFloat = 1.0
    
    let postType: PostType
    
    var body: some View {
        let createdAt = viewModel.post.createdAt.dateValue()
        
        ZStack {
            if !showImageDetail {
                VStack {
                    CustomNavigationBar(
                        leadingType: .back(action: { coordinator.pop() }),
                        centerType: .timeTitle(title: "\(viewModel.postOwnerNickname)의 \(DateUtils.isATime(date: createdAt) ? "오전" : "오후")", timeImage: DateUtils.isATime(date: createdAt) ? "sun.max.fill" : "moon.fill"),
                        trailingType: viewModel.isMyPost ? .menu(items: [
                            CustomNavMenuItem("삭제하기", role: .destructive) {
                                showDeleteConfirmAlert = true
                            }
                        ]) : .none,
                        navigationColor: .black
                    )
                    .padding(.horizontal, 20)
                    .backHiddenSwipeEnabled()
                    .onTapGesture {
                        showStickerSheet = false
                    }
                    
                    ZStack(alignment: .bottomTrailing) {
                        Color.clear
                            .onTapGesture {
                                showStickerSheet = false
                            }
                        
                        PostContentsView(post: viewModel.post, isEditing: $showStickerSheet, viewModel: stickerViewModel, showDetail: $showImageDetail, isFrontOrBack: $isFrontOrBack)
                        
                        if postType == .post {
                            Button {
                                showStickerSheet = true
                            } label: {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 90, height: 90)
                            }
                            .padding(.trailing, 14)
                        }
                    }
                    .sheet(isPresented: $showStickerSheet) {
                        StickerSheetView(
                            viewModel: stickerViewModel,
                            postId: viewModel.post.postId,
                            onRequestCamera: {
                                stickerViewModel.shouldReopenSheetAfterCamera = true
                                showStickerSheet = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    coordinator.push(.camera(isStickerCamera: true))
                                }
                            },
                            gridService: StickerGridService(role: UserPairingStore.shared.myRole ?? "child")
                        )
                        .presentationDetents([.height(317)])
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDragIndicator(.hidden)
                        .background(.ppRealBlack.opacity(0.95))
                        .interactiveDismissDisabled(true)
                    }
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
            } else {
                let magnification = MagnificationGesture()
                    .updating($pinchScale) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        scale = min(max(scale * value, 1.0), 4.0)
                    }
                
                ZStack(alignment: .topTrailing) {
                    Color.ppRealBlack.ignoresSafeArea()
                    
                    GeometryReader { proxy in
                        let centerY = proxy.size.height / 2
                        
                        TabView(selection: $isFrontOrBack) {
                            ImageOnlyView(urlString: viewModel.post.frontImageURL)
                                .tag(0)
                                .scaleEffect(scale * pinchScale)
                                .gesture(magnification)
                            
                            ImageOnlyView(urlString: viewModel.post.backImageURL)
                                .tag(1)
                                .scaleEffect(scale * pinchScale)
                                .gesture(magnification)
                        }
                        .frame(width: proxy.size.width, height: 524 * scale * pinchScale)
                        .position(x: proxy.size.width / 2, y: centerY)
                        .tabViewStyle(.page)
                        .onChange(of: isFrontOrBack) { _, newValue in
                            Task {
                                stickerViewModel.postImageType = (newValue == 0) ? .front : .back
                                await stickerViewModel.fetchStickers()
                            }
                        }
                    }
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding(.top, 54)
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            showImageDetail = false
                        }
                }
                .ignoresSafeArea()
            }
        }
        .background {
            Color.ppWhite
                .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .task {
            Task {
                stickerViewModel.postId = viewModel.post.postId
                await stickerViewModel.fetchStickers()
            }
        }
    }
}

private struct ImageOnlyView: View {
    var urlString: String
    @State private var loadFailed = false
    
    var body: some View {
        KFImage(URL(string: urlString))
            .placeholder {
                Rectangle()
                    .fill(.ddGray500)
            }
            .onFailure { _ in
                loadFailed = true
            }
            .cancelOnDisappear(true)
            .fade(duration: 0.25)
            .resizable()
            .scaledToFill()
            .clipped()
            .overlay(alignment: .center) {
                if loadFailed {
                    Rectangle()
                        .fill(.ddGray500)
                        .overlay(Image(systemName: "photo"))
                }
            }
    }
}
