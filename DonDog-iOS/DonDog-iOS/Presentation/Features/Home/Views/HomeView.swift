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
            CustomNavigationBar(leadingType: .none, centerType: .title(title: "LOGO"), trailingType: .timeType(time: viewModel.isShowingATimePost ? "낮" : "밤"), navigationColor: .black)
                .padding(.horizontal, 16)
            
            CustomSegmentedControl(items: ArchiveSegment.allCases, selectedItem: $viewModel.selectedPostType, titleProvider: { $0.rawValue })
            .padding(.top, 33)
            
            TabView(selection: $viewModel.currentIndex) {
                if let post = viewModel.currentPost, let frontURL = post.frontImageURL, let backURL = post.backImageURL {
                    Group {
                        // 뷰빌더로 변경할 예정
                        KFImage(frontURL)
                            .resizable()
                            .scaledToFit()
                            .blur(radius: DateUtils.isOver3daysSinceLastUpload() ? 12 : 0)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .tag(0)
                        
                        KFImage(backURL)
                            .resizable()
                            .scaledToFit()
                            .blur(radius: DateUtils.isOver3daysSinceLastUpload() ? 12 : 0)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .tag(1)
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
                            .fill(.ddGray200)
                    }
                    .padding(.horizontal, 20)
                    .tag(0)
                    
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ddGray400)
                    }
                    .padding(.horizontal, 20)
                    .tag(1)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(maxHeight: 468)
            .padding(.top, 28)
            
            Spacer()
            
            ZStack {
                Rectangle()
                    .frame(maxHeight: 117)
                    .foregroundStyle(.ddGray400)
                
                HStack {
                    Spacer()
                    Button {
                        coordinator.push(.archive)
                    } label: {
                        VStack(spacing: 2) {
                            Image("CalendarButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                                .foregroundStyle(.ddPrimaryBlue)
                            Text("보관함")
                                .foregroundStyle(.ddPrimaryBlue)
                                .font(.captionRegular14)
                        }
                    }
                    .hapticFeedback(.medium)
                    Spacer()
                    Button {
                        viewModel.isShowCameraView = true
                    }label: {
                        Circle()
                            .foregroundColor(.ddWhite)
                            .frame(width: 80, height: 80)
                            .background {
                                Circle()
                                    .foregroundColor(.ddPrimaryBlue)
                                    .frame(width: 90, height: 90)
                            }
                            .offset(y: -10)
                    }
                    .hapticFeedback(.medium)
                    Spacer()
                    Button {
                        coordinator.push(.stickerCollection)
                    } label: {
                        VStack(spacing: 2) {
                            Image("AddStickerButtonAbled")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                            Text("스티커")
                                .foregroundStyle(.ddPrimaryBlue)
                                .font(.captionRegular14)
                        }
                        
                    }
                    .hapticFeedback(.medium)
                    Spacer()
                }.padding(.bottom, 22)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background {
            if viewModel.isShowingATimePost {
                Color.white
                    .ignoresSafeArea()
            } else {
                Color.indigo
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
