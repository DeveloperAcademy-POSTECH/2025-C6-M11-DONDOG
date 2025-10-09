//
//  CaptionView.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/9/25.
//

import SwiftUI

struct CaptionView: View {
    @ObservedObject var viewModel: CaptionViewModel
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 상단 타이틀
            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("캡션 작성")
                    .font(.headline)
                
                Spacer()
                
                // 빈 공간 (대칭을 위해)
                Image(systemName: "xmark")
                    .font(.title2)
                    .opacity(0)
            }
            .padding()
            
            // 전면/후면 사진 미리보기
            HStack(spacing: 10) {
                if let frontImage = viewModel.frontImage {
                    VStack {
                        Text("전면")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Image(uiImage: frontImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                
                if let backImage = viewModel.backImage {
                    VStack {
                        Text("후면")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Image(uiImage: backImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("캡션 (최대 8자)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("오늘의 한마디를 입력하세요", text: $viewModel.caption)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .onChange(of: viewModel.caption) { newValue in
                        if newValue.count > 8 {
                            viewModel.caption = String(newValue.prefix(8))
                        }
                    }
                
                Text("\(viewModel.caption.count)/8")
                    .font(.caption)
                    .foregroundColor(viewModel.caption.count >= 8 ? .red : .gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal)
            
            Spacer()

            Button(action: {
                print("📤 업로드 버튼 클릭")
                viewModel.uploadPost()
            }) {
                if viewModel.isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("업로드하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(viewModel.isUploading ? Color.gray : Color.blue)
            .cornerRadius(10)
            .disabled(viewModel.isUploading)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color.white)
    }
}

