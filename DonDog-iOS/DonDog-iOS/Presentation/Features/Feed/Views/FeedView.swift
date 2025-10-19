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
    
    var body: some View {
        VStack(spacing: 0){
            //네비게이션 바
            HStack{
                DisclosureGroup("디버깅 용") {
                    HStack{
                        Button("연결뷰로 이동") {
                            coordinator.inviteShowSentHint = false
                            coordinator.push(.invite) }
                        Button("설정뷰로 이동") { coordinator.push(.setting) }
                        Button("로그아웃") {
                            do {
                                try Auth.auth().signOut()
                            } catch {
                                print("로그아웃 실패: \(error.localizedDescription)")
                            }
                        }
                        Spacer()
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
                            coordinator.push(.post(postId: viewModel.selectedPostId, roomId: viewModel.currentRoomId))
                        }
                    }
                }.padding(.horizontal)
                Spacer()
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
            //날짜표시
            HStack {
                Spacer()
                Text(DataUtils.formatDate(.now, format: "MM월 dd일 E요일"))
                    .font(.subtitleSemiBold16)
                    .foregroundStyle(.ddGray600)
                Spacer()
            }
            .padding(.top, 24)
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
            } else if !viewModel.displayablePosts.isEmpty {
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
                                        createdAt: DataUtils.formatDate(displayablePost.createdAt, format: "a hh:mm"),
                                        caption: displayablePost.caption,
                                        onStickerButtonTapped: {
                                            showStickerSheet = true
                                        },
                                        selectedStickerEmotion: viewModel.selectedStickerEmotion,
                                        stickerImage: viewModel.sticker,
                                        isMyPost: displayablePost.isMyPost
                                    )
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
                    .onChange(of: viewModel.currentPostIndex) { newIndex in
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
            } else { // 오늘 찍은 사진이 없을 때
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
                StickerSheetView(
                    stickerImage: sticker,
                    currentSelectedEmotion: viewModel.selectedStickerEmotion,
                    onStickerSelected: { emotion in
                        viewModel.selectedStickerEmotion = emotion
                        
                        // Firebase에 저장
                        if let emotion = emotion {
                            // 감정 선택 시 → Firebase에 저장
                            viewModel.emotion = emotion
                            viewModel.updateStickerData()
                        } else {
                            // 감정 취소 시 → Firebase에서 삭제
                            viewModel.removeStickerData()
                        }
                    }
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
}
