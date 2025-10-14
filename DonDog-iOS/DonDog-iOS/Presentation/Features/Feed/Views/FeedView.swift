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
    @State private var isStickerExist = false
    @State private var emotion = ""
    
    
    var body: some View {
        VStack{
            VStack {
                HStack{
                    DisclosureGroup("디버깅 용") {
                        Button("연결뷰로 이동") { coordinator.push(.invite) }
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
                    }.padding(.horizontal)
                    Spacer()
                    Button{
                        //아카이브 뷰로 이동
                    }label: {
                        Image(systemName: "photo.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding()
                            .foregroundStyle(.ddFeelingBlue)
                    }
                }
                
                HStack {
                    Spacer()
                    Text(DataUtils.formatDate(.now, format: "MM월 dd일 E요일"))
                    Spacer()
                }
                
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
                            
                            if !isStickerExist {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 45))
                                    .zIndex(2)
                                    .onTapGesture {
                                        isSelectingSticker = true
                                    }
                            } else {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 45))
                                    .foregroundStyle(Color.pink)
                                    .zIndex(2)
                                    .onTapGesture {
                                        isSelectingSticker = false
                                        isStickerExist = false
                                    }
                            }
                            
                            if isStickerExist {
                                if let sticker = viewModel.sticker {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: sticker)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 61)
                                        Image(systemName: emotion)
                                    }
                                    .zIndex(3)
                                    .offset(x: -200)
                                } else {
                                    Image(systemName: "smiley")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .zIndex(3)
                                        .offset(x: -200)
                                }
                            }
                        }
                    }
                } else {
                    Image(systemName: "photo.on.rectangle.angled.fill")
                        .resizable()
                        //.foregroundStyle(.ddSecondaryBlue)
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
            }
            
            Button{
                showCameraView = true
            }label: {
                HStack {
                    Image(systemName: "camera")
                    Text("커스텀 카메라로 촬영")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background{
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                }
            }
            Spacer()
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
