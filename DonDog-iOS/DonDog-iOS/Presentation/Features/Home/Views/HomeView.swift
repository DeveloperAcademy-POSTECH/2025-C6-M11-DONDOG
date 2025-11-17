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
            if viewModel.connectUserInfo.isConnected == false {
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
            } else {
                CustomNavigationBar(leadingType: .none, centerType: .title(title: "LOGO"), trailingType: .timeType(time: viewModel.isShowingATimePost ? "낮" : "밤"), navigationColor: .black)
                    .padding(.horizontal, 16)
            }
            
            if viewModel.connectUserInfo.isConnected == false {
                VStack {
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
            } else {
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
        }
        .ignoresSafeArea(edges: .bottom)
        .background {
            if viewModel.connectUserInfo.isConnected == false {
                Color.ppWhite
                    .ignoresSafeArea()
            } else if viewModel.isShowingATimePost {
                Color.ppWhite
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
