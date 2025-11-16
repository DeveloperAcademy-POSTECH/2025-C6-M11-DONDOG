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
                .padding(.horizontal, 16)
            
            CustomSegmentedControl(items: ArchiveSegment.allCases, selectedItem: $viewModel.selectedPostType, titleProvider: { $0.rawValue })
                .padding(.top, 33)
            
            ZStack(alignment: .bottom) {
                TabView(selection: $viewModel.currentIndex) {
                    if let post = viewModel.currentPost, let frontURL = post.frontImageURL, let backURL = post.backImageURL {
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
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 20)
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
            .frame(minHeight: 370, maxHeight: 468)
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
                    viewModel.isShowCameraView = true
                }label: {
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
