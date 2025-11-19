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
    @EnvironmentObject var connectUserInfo: UserPairingStore
    
    var body: some View {
        if connectUserInfo.isConnected == .unknown {
            SplashView()
        } else if connectUserInfo.isConnected == .notConnected {
            ZStack {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            coordinator.push(.setting)
                        } label: {
                            Image(systemName: "gear")
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.ppPrime)
                                .padding(.vertical, 8)
                                .padding(.trailing, 20)
                        }
                    }
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    Image(systemName: "person.fill.xmark")
                        .foregroundStyle(Color.ppPrime50)
                        .font(.system(size: 40))
                    Text("아직 가족과 연결되지 않았어요\n아래 버튼으로 가족을 초대할 수 있어요")
                        .font(.bodyRegular16)
                        .lineSpacing(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.ppGray500)
                        .padding(10)
                    Button {
                        coordinator.inviteShowSentHint = false
                        coordinator.push(.invite)
                    } label: {
                        HStack(alignment: .center, spacing: 10) {
                            Text("가족 초대하기")
                                .foregroundStyle(Color.ppGray200)
                                .font(.captionRegular14)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.ppPrime)
                        .cornerRadius(999)
                    }
                    Spacer()
                }
            }
            .background(.ppWhite)
        } else {
            VStack(spacing: 0) {
                CustomNavigationBar(leadingType: .none, centerType: .logoImage(logoImage: "PicPeekLogo"), trailingType: .timeType(time: viewModel.isShowingATimePost ? "sun.max.fill" : "moon.fill"), navigationColor: .black)
                    .padding(.horizontal, 16)
                
                CustomSegmentedControl(items: ArchiveSegment.allCases, selectedItem: $viewModel.selectedPostType, titleProvider: { $0.rawValue })
                    .padding(.top, 33)
                
                ZStack(alignment: .bottom) {
                    TabView(selection: $viewModel.currentIndex) {
                        if let post = viewModel.currentPost, let frontURL = post.frontImageURL, let backURL = post.backImageURL {
                            Group {
                                KFImage(frontURL)
                                    .resizable()
                                    .scaledToFit()
                                    .blur(radius: DateUtils.isOver3daysSinceLastUpload() ? 12 : 0)
                                    .tag(0)
                                    .overlay(alignment: .bottom) {
                                        LinearGradient(colors: [.clear, .ppBlack], startPoint: .top, endPoint: .bottom)
                                            .opacity(0.6)
                                            .frame(maxHeight: 97)
                                    }
                                    .overlay {
                                        if DateUtils.isOver3daysSinceLastUpload() {
                                            VStack {
                                                Text("게시글을 작성한 지 3일이 지났어요.")
                                                    .font(.titleBold18)
                                                    .foregroundStyle(.ppWhite)
                                                Text("게시글을 업로드해주세요")
                                                    .font(.titleBold18)
                                                    .foregroundStyle(.ppWhite)
                                            }
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .padding(.horizontal, 20)
                                
                                KFImage(backURL)
                                    .resizable()
                                    .scaledToFit()
                                    .blur(radius: DateUtils.isOver3daysSinceLastUpload() ? 12 : 0)
                                    .tag(1)
                                    .overlay(alignment: .bottom) {
                                        LinearGradient(colors: [.clear, .ppBlack], startPoint: .top, endPoint: .bottom)
                                            .opacity(0.6)
                                            .frame(maxHeight: 97)
                                    }
                                    .overlay {
                                        if DateUtils.isOver3daysSinceLastUpload() {
                                            VStack {
                                                Text("게시글을 작성한 지 3일이 지났어요.")
                                                    .font(.titleBold18)
                                                    .foregroundStyle(.ppWhite)
                                                Text("게시글을 업로드해주세요")
                                                    .font(.titleBold18)
                                                    .foregroundStyle(.ppWhite)
                                            }
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .padding(.horizontal, 20)
                            }
                            .onTapGesture {
                                if let currentPost = viewModel.currentPost?.post {
                                    coordinator.push(.post(post: currentPost, postType: .post))
                                }
                            }
                        } else {
                            // 포스트가 없을 때
                            HStack(spacing: 16) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ppGray200)
                                    .overlay {
                                        Text(viewModel.selectedPostType == ArchiveSegment.partnerArchive ? "가족이 아직 사진을 올리지 않았어요." : "오전 게시물을 올릴 수 있는 시간이\n네 시간 남았어요!" )
                                            .multilineTextAlignment(.center)
                                    }
                            }
                            .overlay(alignment: .bottom) {
                                LinearGradient(colors: [.clear, .ppBlack], startPoint: .top, endPoint: .bottom)
                                    .opacity(0.6)
                                    .frame(maxHeight: 97)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 20)
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
                        if !DateUtils.isOver3daysSinceLastUpload() {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currentPost.post.caption)
                                        .font(.subtitleSemiBold16)
                                        .foregroundStyle(.ppWhite)
                                    
                                    Text(DateUtils.string(from: currentPost.createdAt, format: .home))
                                        .font(.captionRegular13)
                                        .foregroundStyle(.ppWhite)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 21)
                                
                                Spacer()
                                Button {
                                    // editableView
                                } label: {
                                    Image("AddStickerButtonAbled")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                        .background {
                                            Circle()
                                                .frame(width: 70, height: 70)
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .buttonStyle(.plain)
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
            .background {
                if viewModel.isShowingATimePost {
                    Color.ppWhite
                        .ignoresSafeArea()
                } else {
                    Color.ppWhite
                        .ignoresSafeArea()
                }
            }
            .task {
                if coordinator.showCameraInDeeplink {
                    viewModel.isShowCameraView = true
                    coordinator.showCameraInDeeplink = false
                }
            }
            .animation(.smooth(duration: 0.5), value: viewModel.isShowingATimePost)
            .fullScreenCover(isPresented: $viewModel.isShowCameraView) {
                CameraViewContainer(
                    cameraViewModel: cameraViewModel,
                    delegate: viewModel,
                    isPresented: $viewModel.isShowCameraView,
                    isStickerCamera: false
                )
            }
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
