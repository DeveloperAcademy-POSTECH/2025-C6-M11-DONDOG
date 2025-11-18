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
                        centerType: .timeTitle(title: DateUtils.string(from: createdAt, format: .monthDay), timeImage: DateUtils.isATime(date: createdAt) ? "sun.max" : "moon.fill"),
                        trailingType: viewModel.isMyPost ? .menu(items: [
                            CustomNavMenuItem("삭제하기", role: .destructive) {
                                showDeleteConfirmAlert = true
                            }
                        ]) : .none,
                        navigationColor: .black
                    )
                    .padding(.horizontal, 20)
                    .backHiddenSwipeEnabled()
                    .alert("삭제하시겠습니까?", isPresented: $showDeleteConfirmAlert) {
                        Button("취소", role: .cancel) { }
                        
                        Button("삭제하기", role: .destructive) {
                            Task {
                                await viewModel.deletePost()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    coordinator.pop()
                                }
                            }
                        }
                    } message: {
                        Text("게시물이 완전히 사라져요")
                    }
                    
                    ZStack(alignment: .bottomTrailing) {
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
                            onRequestCamera: {
                                stickerViewModel.shouldReopenSheetAfterCamera = true
                                showStickerSheet = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    coordinator.push(.camera)
                                }
                            }
                            
                        )
                        .presentationDetents([.height(270)])
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDragIndicator(.hidden)
                        .background(Color.ddGray100.opacity(0.5))
                    }
                    .padding(.trailing, 14)
                }
            }
            .sheet(isPresented: $showStickerSheet) {
                StickerSheetView(
                    viewModel: stickerViewModel, postId: viewModel.post.postId,
                    onRequestCamera: {
                        stickerViewModel.shouldReopenSheetAfterCamera = true
                        showStickerSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            coordinator.push(.camera)
                        }
                    }
                    
                    Spacer()
                }
            } else {
                let magnification = MagnificationGesture()
                    .updating($pinchScale) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        scale = min(max(scale * value, 1.0), 4.0)
                    }
                
                ZStack(alignment: .topTrailing) {
                    Color.ppBlack.ignoresSafeArea()
                    
                    GeometryReader { proxy in
                        let centerY = proxy.size.height / 2
                        
                        TabView(selection: $isFrontOrBack) {
                            ImageView(urlString: viewModel.post.frontImageURL, isEditing: $showStickerSheet, viewModel: stickerViewModel)
                                .tag(0)
                                .scaleEffect(scale * pinchScale)
                                .gesture(magnification)
                            
                            ImageView(urlString: viewModel.post.backImageURL, isEditing: $showStickerSheet, viewModel: stickerViewModel)
                                .tag(1)
                                .scaleEffect(scale * pinchScale)
                                .gesture(magnification)
                        }
                        .frame(width: proxy.size.width, height: 524 * scale * pinchScale)
                        .position(x: proxy.size.width / 2, y: centerY)
                        .tabViewStyle(.page)
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
        .navigationBarBackButtonHidden(true)
        .task {
            Task {
                stickerViewModel.postId = viewModel.post.postId
                await stickerViewModel.fetchStickers()
            }
        }
        
        Spacer()
    }
}
