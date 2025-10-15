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

struct FeedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: FeedViewModel
    
    @State var showCameraView: Bool = false
    @State private var isRefreshing = false
    @State private var isFrontImageOnTop = true
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var isSelectingSticker = false
    @State private var emotion = "null"
    
    var body: some View {
        VStack(spacing: 0){
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
                        
                        Button("사진 뒤집기"){
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isFrontImageOnTop.toggle()
                            }
                        }
                    }
                }.padding(.horizontal)
                Spacer()
                Button{
                    //아카이브 뷰로 이동
                }label: {
                    Image(systemName: "photo.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.ddPrimaryBlue)
                        .padding(.vertical, 8)
                        .padding(.trailing, 20)
                }
            }
            
            HStack {
                Spacer()
                Text(DataUtils.formatDate(.now, format: "MM월 dd일 E요일"))
                    .font(.subtitleSemiBold16)
                    .foregroundStyle(.ddGray600)
                Spacer()
            }
            .padding(.top, 24)
            
            if let frontImage = viewModel.todayFrontImage, let backImage = viewModel.todayBackImage {
                VStack(spacing: 10) {
                    ZStack(alignment: .bottomTrailing) {
                        polaroidView(
                            image: backImage,
                            label: "후면",
                            isFlipped: !isFrontImageOnTop
                        )
                        .rotationEffect(.degrees(-5))
                        .offset(x: -20, y: -10)
                        .zIndex(isFrontImageOnTop ? 0 : 1)
                        polaroidView(
                            image: frontImage,
                            label: "전면",
                            isFlipped: isFrontImageOnTop
                        )
                        .rotationEffect(.degrees(5))
                        .offset(x: 20, y: 10)
                        .zIndex(isFrontImageOnTop ? 1 : 0)
                        .onTapGesture {
                            coordinator.push(.post(postId: viewModel.selectedPostId, roomId: viewModel.currentRoomId))
                        }
                        
                        if emotion != "null" {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: viewModel.sticker ?? UIImage())
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 61)
                                Image(systemName: emotion)
                            }
                            .onTapGesture {
                                isSelectingSticker = true
                            }
                            .zIndex(2)
                        } else {
                            Image(systemName: "smiley")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .zIndex(2)
                                .onTapGesture {
                                    isSelectingSticker = true
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
                }.padding(.top, 220)
                    
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
                        if emotion != "heart.fill" {
                            emotion = "heart.fill"
                        } else {
                            emotion = "null"
                        }
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
                        if emotion != "drop.fill" {
                            emotion = "drop.fill"
                        } else {
                            emotion = "null"
                        }
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
                        if emotion != "heart.badge.bolt.fill" {
                            emotion = "heart.badge.bolt.fill"
                        } else {
                            emotion = "null"
                        }
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
                        if emotion != "eyes.inverse" {
                            emotion = "eyes.inverse"
                        } else {
                            emotion = "null"
                        }
                        isSelectingSticker = false
                    }
                }
            }
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
            }.padding(.top, 278)
            
            Spacer()
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
