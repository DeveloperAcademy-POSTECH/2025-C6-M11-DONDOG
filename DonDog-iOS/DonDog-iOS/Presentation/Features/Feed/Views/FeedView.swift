//
//  FeedView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import FirebaseAuth
import PhotosUI
import SwiftUI
import UIKit
import FirebaseCore

struct FeedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: FeedViewModel
    
    @State var showCameraView: Bool = false
    @State private var isRefreshing = false
    @State private var isFrontImageOnTop = true
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var isSelectingSticker = false
    @State private var showStickerSheet = false
    
    @EnvironmentObject var connectState: ConnectStateService
    
    var body: some View {
        VStack(spacing: 0){
            //네비게이션 바
            HStack{
                DisclosureGroup("디버깅 용") {
                    HStack{
                        Button(action: {
                            print("🔄 수동 새로고침 시작")
                            withAnimation(.linear(duration: 1).repeatCount(1, autoreverses: false)) {
                                isRefreshing = true
                            }
                            viewModel.loadTodayPosts()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isRefreshing = false
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        }
                        .disabled(viewModel.isLoading)

                        Button("게시글 상세로 이동"){
                            coordinator.push(.post(postId: viewModel.currentPost?.postId ?? "", roomId: viewModel.currentRoomId))
                        }
                    }
                }.padding(.horizontal)
                Spacer()
                if connectState.isConnected == false {
                                    Button{
                                        coordinator.push(.setting)
                                    }label: {
                                        Image(systemName: "gear")
                                            .frame(width: 24, height: 24)
                                            .foregroundStyle(Color.ddPrimaryBlue)
                                            .padding(.vertical, 8)
                                            .padding(.trailing, 20)
                                    }
                } else {
                    Button{
                        coordinator.push(.archive(roomId: viewModel.currentRoomId))
                    }label: {
                        Image(systemName: "photo.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.ddPrimaryBlue)
                            .padding(.vertical, 8)
                            .padding(.trailing, 20)
                    }
                }
            }
            
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.ddPrimaryBlue)
                    Text("게시물을 불러오는 중...")
                        .font(.bodyMedium16)
                        .foregroundStyle(.ddGray600)
                }
                .padding(.top, 220)
            }else if connectState.isConnected == false {
                VStack{
                    Spacer()
                    Image(systemName: "person.fill.xmark")
                        .foregroundStyle(Color.ddSecondaryBlue)
                        .font(.system(size: 40))
                    Text("아직 가족과 연결되지 않았어요\n아래 버튼으로 가족을 초대할 수 있어요")
                        .font(.bodyRegular16)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.ddSecondaryBlue)
                        .padding(10)
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
                        .background(Color.ddPrimaryBlue)
                        .cornerRadius(999)
                    }
                    Spacer()
                }
            }  else if !viewModel.displayablePosts.isEmpty {
                VStack(spacing: 0){
                    TabView(selection: $viewModel.currentPostIndex) {
                        ForEach(Array(viewModel.displayablePosts.enumerated()), id: \.element.id) { index, displayablePost in
                            if let frontImage = displayablePost.frontImage,
                               let backImage = displayablePost.backImage {
                                HStack {
                                    Spacer()
                                    PolaroidSetView(
                                        frontImage: frontImage,
                                        backImage: backImage,
                                        nickname: displayablePost.nickname,
                                        createdAt: DataUtils.relativeTimeString(from: displayablePost.createdAt),
                                        caption: displayablePost.caption,
                                        onStickerButtonTapped: {
                                            showStickerSheet = true
                                        },
                                        selectedStickerEmotion: displayablePost.stickerType,
                                        stickerImage: displayablePost.stickerImage,
                                        isMyPost: displayablePost.isMyPost
                                    )
                                    .onAppear {
                                        print("🎨 게시물 \(index) 렌더링: stickerType=\(displayablePost.stickerType ?? "nil"), stickerImage=\(displayablePost.stickerImage != nil ? "있음" : "없음")")
                                    }
                                    .allowsHitTesting(true)
                                    .scaleEffect(index == viewModel.currentPostIndex ? 1.0 : 0.95)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentPostIndex)
                                }
                                .padding(.top, 93)
                                .padding(.trailing, 26)
                                .tag(index)
                            }
                        }
                    }
                    .frame(height: 520)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPostIndex)
                    .onChange(of: viewModel.currentPostIndex) { oldValue, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.updateCurrentPost(at: newIndex)
                        }
                    }
                    if viewModel.displayablePosts.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<viewModel.displayablePosts.count, id: \.self) { index in
                                Circle()
                                    .fill(index == viewModel.currentPostIndex ? Color.ddPrimaryBlue : Color.ddGray300)
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPostIndex)
                            }
                        }
                        .padding(.top, 16)
                    }
                }
            } else {
                VStack(spacing: 10){
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .foregroundStyle(.ddSecondaryBlue)
                        .scaledToFit()
                        .frame(width: 60)
                    Text("아직 사진이 없어요\n오늘의 첫 게시물을 올려 볼까요?")
                        .multilineTextAlignment(.center)
                        .font(.bodyMedium16)
                        .foregroundStyle(.ddSecondaryBlue)
                }
                .padding(.top, 220)
            }
            Spacer()
            if connectState.isConnected == true{
                Button{
                    showCameraView = true
                }label: {
                    Circle()
                        .foregroundColor(.ddWhite)
                        .frame(width: 64, height: 64)
                        .background{
                            Circle()
                                .foregroundColor(.ddPrimaryBlue)
                                .frame(width: 72, height: 72)
                        }
                }
                .padding(.bottom, 22)
            }
        }
        .onAppear() {
            viewModel.loadTodayPosts()
        }
        .background{
            LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(0.35)
        }
        .fullScreenCover(isPresented: $showCameraView) {
            CameraViewContainer(
                cameraViewModel: cameraViewModel,
                feedViewModel: viewModel,
                isPresented: $showCameraView
            )
        }
        .sheet(isPresented: $showStickerSheet) {
            if let sticker = viewModel.sticker {
                let currentPost = viewModel.displayablePosts[viewModel.currentPostIndex]
                StickerSheetView(
                    stickerImage: sticker,
                    currentSelectedEmotion: currentPost.stickerType,
                    onStickerSelected: { emotion in
                        if let emotion = emotion {
                            viewModel.emotion = emotion
                            viewModel.updateStickerData()
                        } else {
                            viewModel.removeStickerData()
                        }
                    },
                    borderedStickers: viewModel.borderedStickers 
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
                .background(Color.ddWhite)
            } else {
                Text("스티커를 만들 사진이 없어요")
            }
        }
    }
}

#Preview {
    let coordinator = AppCoordinator(factory: ModuleFactory.shared)
    FeedView(viewModel: FeedViewModel())
        .environmentObject(coordinator)
        .environmentObject(ConnectStateService.shared)
}
