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
    @FocusState private var isCaptionFocused: Bool
    
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
            
            HStack(spacing: 10) {
                if let frontImage = viewModel.frontImage {
                    VStack {
                        Text("전면")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Image(uiImage: frontImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(x: -1, y:1)
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
            
            VStack(alignment: .leading, spacing: 15) {
                Text("캡션 (최대 8자)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // 글자별 박스 표시
                HStack(spacing: 8) {
                    ForEach(0..<8, id: \.self) { index in
                        ZStack {
                            // 박스 테두리
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(index < viewModel.caption.count ? Color.black : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 40, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(index < viewModel.caption.count ? Color.white : Color.gray.opacity(0.05))
                                )
                            
                            // 글자 표시
                            if index < viewModel.caption.count {
                                let character = Array(viewModel.caption)[index]
                                Text(String(character))
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.black)
                            } else {
                                // 빈 박스 placeholder
                                Text("")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                        .onTapGesture {
                            isCaptionFocused = true
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // 숨겨진 TextField (실제 입력받기 위함)
                TextField("", text: $viewModel.caption)
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .focused($isCaptionFocused)
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
            .onChange(of: viewModel.isUploading) { newValue in
                if newValue == false{
                    onCancel()
                }
            }
        }
        .background(Color.white)
    }
}

#Preview {
    CaptionView(viewModel: CaptionViewModel(frontImage: UIImage(named: "test1"), backImage: UIImage(named: "test2")), onCancel: {})
}
