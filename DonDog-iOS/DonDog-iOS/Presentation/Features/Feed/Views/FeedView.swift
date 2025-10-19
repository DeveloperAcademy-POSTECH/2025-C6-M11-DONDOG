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
    
    @EnvironmentObject var connectState: ConnectState
    
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
                            coordinator.push(.post(postId: viewModel.selectedPostId, roomId: viewModel.currentRoomId))
                        }
                    }
                }
                .padding(.horizontal)
                .frame(width: 200)
                
                Spacer()
                
                if connectState.isConnected == false {
                    Button{
                        coordinator.push(.setting)
                    }label: {
                        Image(systemName: "gear")
                            .font(.body)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.ddPrimaryBlue)
                    }
                } else {
                    Button{
                        coordinator.push(.archive(roomId: ConnectState.shared.roomId ?? ""))
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
            
            if connectState.isConnected == false {
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
            } else {
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
                    ZStack{
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
                        if viewModel.emotion != "null" {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: viewModel.sticker ?? UIImage())
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 61)
                                Image(systemName: viewModel.emotion)
                            }
                            .onTapGesture {
                                if viewModel.isNotMyPost {
                                    isSelectingSticker.toggle()
                                }
                            }
                            .zIndex(2)
                        } else {
                            if viewModel.isNotMyPost {
                                Image(systemName: "smiley")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                    .zIndex(2)
                                    .onTapGesture {
                                        isSelectingSticker.toggle()
                                    }
                            }
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
                            if viewModel.emotion != "heart.fill" {
                                viewModel.emotion = "heart.fill"
                            } else {
                                viewModel.emotion = "null"
                            }
                            isSelectingSticker = false
                            viewModel.updateStickerData()
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
                            if viewModel.emotion != "drop.fill" {
                                viewModel.emotion = "drop.fill"
                            } else {
                                viewModel.emotion = "null"
                            }
                            isSelectingSticker = false
                            viewModel.updateStickerData()
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
                            if viewModel.emotion != "heart.badge.bolt.fill" {
                                viewModel.emotion = "heart.badge.bolt.fill"
                            } else {
                                viewModel.emotion = "null"
                            }
                            isSelectingSticker = false
                            viewModel.updateStickerData()
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
                            if viewModel.emotion != "eyes.inverse" {
                                viewModel.emotion = "eyes.inverse"
                            } else {
                                viewModel.emotion = "null"
                            }
                            isSelectingSticker = false
                            viewModel.updateStickerData()
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
        .environmentObject(ConnectState.shared)
}
