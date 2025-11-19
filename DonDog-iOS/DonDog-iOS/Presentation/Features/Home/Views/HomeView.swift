//
//  HomeView.swift
//  DonDog-iOS
//
//  Created by Ito on 11/3/25.
//

import Kingfisher
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: HomeViewModel
    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var stickerViewModel = StickerViewModel()
    @EnvironmentObject var connectUserInfo: UserPairingStore
    
    var body: some View {
        if connectUserInfo.isConnected == .unknown {
            SplashView()
        } else if connectUserInfo.isConnected == .notConnected {
            NotConnectedView()
        } else {
            VStack(spacing: 0) {
                CustomNavigationBar(leadingType: .none, centerType: .logoImage(logoImage: "PicPeekLogo"), trailingType: .timeType(time: viewModel.isShowingATimePost ? "sun.max.fill" : "moon.fill"), navigationColor: .black)
                    .padding(.horizontal, 26)
                
                if !viewModel.isShowStickerSheet {
                    CustomSegmentedControl(items: ArchiveSegment.allCases, selectedItem: $viewModel.selectedPostType, titleProvider: { $0.rawValue })
                        .padding(.top, 33)
                }
                
                ZStack(alignment: .bottom) {
                    TabView(selection: $viewModel.currentIndex) {
                        if viewModel.isUploadingLocalImage, viewModel.selectedPostType == .myArchive, let frontImage = viewModel.localFrontImage, let backImage = viewModel.localBackImage {
                            Group {
                                TabItemView(viewModel: stickerViewModel, isEditing: $viewModel.isShowStickerSheet, imageSource: .local(frontImage), tag: 0, postId: nil)
                                TabItemView(viewModel: stickerViewModel, isEditing: $viewModel.isShowStickerSheet, imageSource: .local(backImage), tag: 1, postId: nil)
                            }
                        } else if let post = viewModel.currentPost, let frontURL = post.frontImageURL, let backURL = post.backImageURL {
                            Group {
                                TabItemView(viewModel: stickerViewModel, isEditing: $viewModel.isShowStickerSheet, imageSource: .remote(frontURL), tag: 0, postId: post.postId)
                                TabItemView(viewModel: stickerViewModel, isEditing: $viewModel.isShowStickerSheet, imageSource: .remote(backURL), tag: 1, postId: post.postId)
                            }
                        } else {
                            HomeEmptyView(selectedPostType: viewModel.selectedPostType)
                                .tag(0)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .tint(.ppPrime)
                    .onAppear {
                        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.ppPrime)
                        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.ppPrime50)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    if let currentPost = viewModel.currentPost {
                        if !DateUtils.isOver3daysSinceLastUpload() && !viewModel.isShowStickerSheet {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    if viewModel.isUploadingLocalImage, let localCaption = viewModel.localCaption {
                                        Text(localCaption)
                                            .font(.subtitleSemiBold16)
                                            .foregroundStyle(.ppWhite)
                                        
                                        if let localDate = viewModel.localUploadDate {
                                            Text(DateUtils.string(from: localDate, format: .home))
                                                .font(.captionRegular13)
                                                .foregroundStyle(.ppWhite)
                                        }
                                    } else {
                                        Text(currentPost.post.caption)
                                            .font(.subtitleSemiBold16)
                                            .foregroundStyle(.ppWhite)
                                        
                                        Text(DateUtils.string(from: currentPost.createdAt, format: .home))
                                            .font(.captionRegular13)
                                            .foregroundStyle(.ppWhite)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 21)
                                
                                Spacer()
                                
                                Button {
                                    if let currentPost = viewModel.currentPost {
                                        stickerViewModel.postId = currentPost.postId
                                        stickerViewModel.postImageType = viewModel.currentIndex == 0 ? .front : .back
                                        Task {
                                            await stickerViewModel.fetchStickers()
                                        }
                                    }
                                    viewModel.isShowStickerSheet = true
                                } label: {
                                    Image("AddStickerIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                        .background {
                                            Circle()
                                                .frame(width: 70, height: 70)
                                                .foregroundStyle(.ppPrime)
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .buttonStyle(.plain)
                                .opacity(viewModel.selectedPostType == .myArchive ? 0 : 1)
                            }
                            .padding(.horizontal, 20)
                        }
                    } else if viewModel.isUploadingLocalImage, let localCaption = viewModel.localCaption {
                        if !DateUtils.isOver3daysSinceLastUpload() {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(localCaption)
                                        .font(.subtitleSemiBold16)
                                        .foregroundStyle(.ppWhite)
                                    
                                    if let localDate = viewModel.localUploadDate {
                                        Text(DateUtils.string(from: localDate, format: .home))
                                            .font(.captionRegular13)
                                            .foregroundStyle(.ppWhite)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 21)
                                
                                Spacer()
                                Button {
                                    // editableView
                                } label: {
                                    Image("AddStickerIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                        .background {
                                            Circle()
                                                .frame(width: 70, height: 70)
                                                .foregroundStyle(.ppPrime)
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .buttonStyle(.plain)
                                .opacity(viewModel.selectedPostType == .myArchive ? 0 : 1)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .frame(maxHeight: 468)
                .padding(.top, 16)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button {
                        coordinator.push(.archive)
                    } label: {
                        VStack(spacing: 2) {
                            Image("ArchiveIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 51)
                            Text("보관함")
                                .foregroundStyle(.ppGray500)
                                .font(.captionRegular14)
                        }
                    }
                    .frame(width: 65)
                    .hapticFeedback(.medium)
                    Spacer()
                    Button {
                        cameraViewModel.resetCameraState()
                        viewModel.isShowCameraView = true
                    } label: {
                        Circle()
                            .foregroundColor(.ppWhite)
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 0)
                            .background {
                                Circle()
                                    .foregroundColor(.ppPrime)
                                    .frame(width: 72, height: 72)
                            }
                    }
                    .hapticFeedback(.medium)
                    Spacer()
                    Button {
                        coordinator.push(.stickerCollection)
                    } label: {
                        VStack(spacing: 2) {
                            Image("MakeStickerIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 51)
                            Text("스티커 제작")
                                .foregroundStyle(.ppGray500)
                                .font(.captionRegular14)
                        }
                        
                    }
                    .frame(width: 65)
                    .hapticFeedback(.medium)
                    Spacer()
                }
                .padding(.vertical, 22)
                .padding(.bottom, 12)
                .background {
                    Rectangle()
                        .foregroundStyle(.ppGray200)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                Task {
                    await viewModel.loadPosts()
                }
            }
            .sheet(isPresented: $viewModel.isShowStickerSheet) {
                if let currentPost = viewModel.currentPost {
                    StickerSheetView(
                        viewModel: stickerViewModel, postId: currentPost.postId,
                        onRequestCamera: {
                            stickerViewModel.shouldReopenSheetAfterCamera = true
                            viewModel.isShowStickerSheet = false
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
            }
            .background {
                if viewModel.isShowingATimePost {
                    Color.ppWhite
                        .ignoresSafeArea()
                } else {
                    Color.ppWhite
                        .ignoresSafeArea()
                }
            }
            .animation(.smooth(duration: 0.5), value: viewModel.isShowingATimePost)
            .animation(.smooth(duration: 0.5), value: viewModel.isShowStickerSheet)
            .fullScreenCover(isPresented: $viewModel.isShowCameraView) {
                CameraViewContainer(
                    cameraViewModel: cameraViewModel,
                    delegate: viewModel,
                    isPresented: $viewModel.isShowCameraView
                )
            }
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
