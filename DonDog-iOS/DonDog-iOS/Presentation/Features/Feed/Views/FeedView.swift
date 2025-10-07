//
//  FeedView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Foundation
import SwiftUI
import UIKit
import PhotosUI
import FirebaseAuth

struct FeedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: FeedViewModel
    
    @State var showCameraView: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                ScrollView {
                    // 이미지 표시 영역
                    VStack {
                        Text("Feed View")
                        
                        Button("로그아웃") {
                            do {
                                try Auth.auth().signOut()
                            } catch {
                                print("로그아웃 실패: \(error.localizedDescription)")
                            }
                        }
                    }
                    if let frontImage = viewModel.selectedFrontImage, let backImage = viewModel.selectedBackImage {
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
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "camera")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("커스텀 카메라로 사진을 촬영하세요")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            )
                            .padding()
                    }
                    
                    // 촬영 버튼
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
                    
                    // 이미지 삭제 버튼
                    if viewModel.selectedFrontImage != nil || viewModel.selectedBackImage != nil {
                        Button{
                            viewModel.selectedFrontImage = nil
                            viewModel.selectedBackImage = nil
                        }label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("이미지 삭제")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background{
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.red)
                            }
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle("Boomoji")
        }
        .fullScreenCover(isPresented: $showCameraView) {
            ModuleFactory.shared.makeCameraView(with: viewModel)
                .ignoresSafeArea()
        }
        PostView()
    }
}
#Preview {
    FeedView(viewModel: FeedViewModel())
}
