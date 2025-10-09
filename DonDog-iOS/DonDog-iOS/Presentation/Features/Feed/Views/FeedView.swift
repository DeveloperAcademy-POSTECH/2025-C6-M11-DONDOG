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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                ScrollView {
                    // 이미지 표시 영역
                    VStack {
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
                            ZStack{
                                Image(uiImage: backImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 400)
                                    .cornerRadius(15)
                                    .shadow(radius: 10)
                                Image(uiImage: frontImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(x: -1, y:1)
                                    .frame(maxHeight: 100)
                                    .cornerRadius(15)
                                    .shadow(radius: 10)
                                    .padding()
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
        }
        .fullScreenCover(isPresented: $showCameraView) {
            ModuleFactory.shared.makeCameraView(with: viewModel)
                .ignoresSafeArea()
        }
    }
}
#Preview {
    FeedView(viewModel: FeedViewModel())
}
