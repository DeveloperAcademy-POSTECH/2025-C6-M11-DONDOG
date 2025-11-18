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
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(leadingType: .none, centerType: .logoImage(logoImage: "PicPeekLogo"), trailingType: .timeType(time: viewModel.isShowingATimePost ? "sun.max.fill" : "moon.fill"), navigationColor: .black)
                .padding(.horizontal, 26)
            
            if viewModel.connectUserInfo.isConnected {
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
                                        VStack {
                                            Image("EmptyImage")
                                            if viewModel.selectedPostType == ArchiveSegment.partnerArchive {
                                                Text("가족이 아직 사진을 올리지 않았어요.")
                                                    .font(.subtitleSemiBold16)
                                                    .foregroundStyle(.ppGray700)
                                                Text("조금만 기다려 주세요. 사진이 곧 찾아올 거예요.")
                                                    .font(.captionRegular14)
                                                    .foregroundStyle(.ppGray500)
                                                    .padding(.top, 2)
                                            } else {
                                                let remainingTime = DateUtils.remainingHoursForUpload()
                                                Text("\(remainingTime.period) 게시물을 올릴 수 있는 시간이")
                                                    .multilineTextAlignment(.center)
                                                    .font(.subtitleSemiBold16)
                                                    .foregroundStyle(.ppGray700)
                                                HStack(spacing: 0) {
                                                    Text("\(remainingTime.hours)시간")
                                                        .foregroundStyle(.ppPrime)
                                                    Text(" 남았어요!")
                                                        .foregroundStyle(.ppGray700)
                                                }
                                                .font(.subtitleSemiBold16)
                                                .padding(.top, 1)
                                            }
                                        }
                                    }
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
                    }label: {
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
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "person.fill.xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58)
                    Text("아직 가족과 연결되지 않았어요")
                    Text("아래 버튼으로 가족을 초대할 수 있어요")
                    Button {
                        coordinator.inviteShowSentHint = false
                        coordinator.push(.invite)
                    } label: {
                        HStack(alignment: .center, spacing: 10) {
                            Text("가족 초대하기")
                                .foregroundStyle(Color.ddGray100)
                                .font(.captionRegular14)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.ppPrime)
                        .cornerRadius(999)
                    }
                    Spacer()
                }
                .padding(.bottom, 62)
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
        .animation(.smooth(duration: 0.5), value: viewModel.isShowingATimePost)
        .fullScreenCover(isPresented: $viewModel.isShowCameraView) {
            CameraViewContainer(
                cameraViewModel: cameraViewModel,
                delegate: viewModel,
                isPresented: $viewModel.isShowCameraView
            )
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
