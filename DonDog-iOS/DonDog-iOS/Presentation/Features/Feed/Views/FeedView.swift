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
    
    
    var body: some View {
        VStack(spacing: 30) {
            ScrollView {
                // 이미지 표시 영역
                VStack {
                    Button("설정뷰로 이동") { coordinator.push(.setting) }
                    
                    HStack {
                        Text("Feed View")
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
                        .padding(.trailing, 10)
                        Button("사진 뒤집기"){
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isFrontImageOnTop.toggle()
                            }
                        }
                        Button("로그아웃") {
                            do {
                                try Auth.auth().signOut()
                            } catch {
                                print("로그아웃 실패: \(error.localizedDescription)")
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if let frontImage = viewModel.todayFrontImage, let backImage = viewModel.todayBackImage {
                        VStack(spacing: 10) {
                            ZStack{
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
                            }
                            
                            // 캡션 표시
                            if let firstPost = viewModel.images.first, !firstPost.caption.isEmpty {
                                Text(firstPost.caption)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    } else if viewModel.isLoading {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text("로딩 중...")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                        .padding(.top, 10)
                                }
                            )
                            .padding()
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "camera")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("게시물을 올려주세요")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                        .padding(.top, 10)
                                    Text("오늘 찍은 사진이 없습니다")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            )
                            .padding()
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
        .navigationTitle("Boomoji")
        .fullScreenCover(isPresented: $showCameraView) {
            CameraViewContainer(
                cameraViewModel: cameraViewModel,
                feedViewModel: viewModel,
                isPresented: $showCameraView
            )
        }
        .navigationTitle("Boomoji")
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
