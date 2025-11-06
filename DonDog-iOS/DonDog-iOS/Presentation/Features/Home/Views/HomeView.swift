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
            CustomNavigationBar(leadingType: .none, centerType: .title(title: "LOGO"), trailingType: .changeTime(action: { viewModel.toggleTimeType() }, time: viewModel.isShowingATimePost ? "낮" : "밤"), navigationColor: .black)
                .padding(.horizontal, 16)
            
            Button {
                viewModel.togglePostType()
                viewModel.currentIndex = 0
            } label: {
                Text(viewModel.isShowingMyPost ? "나" : "너")
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 99)
                    .fill(.ddGray200)
            }
            .padding(.top, 33)
            
            TabView(selection: $viewModel.currentIndex) {
                if let post = viewModel.currentPost, let frontURL = post.frontImageURL, let backURL = post.backImageURL {
                    KFImage(frontURL)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .tag(0)
                    
                    KFImage(backURL)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .tag(1)
                } else {
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
                        //
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
