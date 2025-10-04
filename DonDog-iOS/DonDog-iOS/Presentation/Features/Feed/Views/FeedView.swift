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

struct FeedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: FeedViewModel
    
    @State var showCameraView: Bool = false
    @State var selectedFrontImage: UIImage?
    @State var selectedBackImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 이미지 표시 영역
                if let frontImage = selectedFrontImage, let backImage = selectedBackImage {
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
                if selectedFrontImage != nil || selectedBackImage != nil {
                    Button{
                        selectedFrontImage = nil
                        selectedBackImage = nil
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
            .navigationTitle("Boomoji")
        }
        .fullScreenCover(isPresented: $showCameraView) {
            CameraView(viewModel: CameraViewModel())
                .ignoresSafeArea()
        }
    }
}

#Preview {
    FeedView(viewModel: FeedViewModel())
}
