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
    @State private var isStickerExist = false
    @State private var emotion = ""
    
    
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
            //피드
            if let frontImage = viewModel.todayFrontImage, 
               let backImage = viewModel.todayBackImage,
               let currentPost = viewModel.currentPost {
                HStack{
                    Spacer()
                    PolaroidSetView(
                        frontImage: frontImage, 
                        backImage: backImage,
                        nickname: viewModel.currentNickname,
                        createdAt: DataUtils.formatDate(currentPost.createdAt.dateValue(), format: "a hh:mm"),
                        caption: currentPost.caption
                    )
                    .allowsHitTesting(true)
                }.padding(.top, 103)
                .padding(.trailing, 26)
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
            
            if isSelectingSticker {
                HStack(spacing: 29) {
                    ZStack(alignment: .topTrailing) {
                        if let sticker = viewModel.sticker {
                            Image(uiImage: sticker)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 37)
                        } else {
                            Image(systemName: "smiley")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                        Image(systemName: "heart.fill")
                    }
                    .onTapGesture {
                        emotion = "heart.fill"
                        isStickerExist = true
                        isSelectingSticker = false
                    }
                    
                    ZStack(alignment: .topTrailing) {
                        if let sticker = viewModel.sticker {
                            Image(uiImage: sticker)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 37)
                        } else {
                            Image(systemName: "smiley")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                        Image(systemName: "drop.fill")
                    }
                    .onTapGesture {
                        emotion = "drop.fill"
                        isStickerExist = true
                        isSelectingSticker = false
                    }
                    
                    ZStack(alignment: .topTrailing) {
                        if let sticker = viewModel.sticker {
                            Image(uiImage: sticker)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 37)
                        } else {
                            Image(systemName: "smiley")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                        Image(systemName: "heart.badge.bolt.fill")
                    }
                    .onTapGesture {
                        emotion = "heart.badge.bolt.fill"
                        isStickerExist = true
                        isSelectingSticker = false
                    }
                    
                    ZStack(alignment: .topTrailing) {
                        if let sticker = viewModel.sticker {
                            Image(uiImage: sticker)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 37)
                        } else {
                            Image(systemName: "smiley")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                        Image(systemName: "eyes.inverse")
                    }
                    .onTapGesture {
                        emotion = "eyes.inverse"
                        isStickerExist = true
                        isSelectingSticker = false
                    }
                }
            }
            Spacer()
            Button{
                showCameraView = true
            }label: {
                Circle()
                .foregroundColor(.ddWhite)
                .frame(width: 50, height: 50)
                .background{
                    Circle()
                        .foregroundColor(.ddPrimaryBlue)
                        .frame(width: 60, height: 60)
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
    }
    
    private func polaroidView(image: UIImage, label: String, isFlipped: Bool) -> some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .padding(12)
                .background(Color.white)
            VStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 204, height: 40)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(4)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    let coordinator = AppCoordinator(factory: ModuleFactory.shared)
    FeedView(viewModel: FeedViewModel())
        .environmentObject(coordinator)
}
