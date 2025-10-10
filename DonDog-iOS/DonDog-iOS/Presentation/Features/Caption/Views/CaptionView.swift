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
    @State private var isFrontImageOnTop = true 
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
            }
            .padding()
 
            ZStack {
                if let frontImage = viewModel.frontImage, let backImage = viewModel.backImage {
                    polaroidView(
                        image: backImage,
                        label: "후면",
                        isFlipped: !isFrontImageOnTop
                    )
                    .rotationEffect(.degrees(-5))
                    .offset(x: -20, y: -10)
                    .zIndex(isFrontImageOnTop ? 0 : 1)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFrontImageOnTop.toggle()
                        }
                    }

                    polaroidView(
                        image: frontImage,
                        label: "전면",
                        isFlipped: isFrontImageOnTop
                    )
                    .rotationEffect(.degrees(5))
                    .offset(x: 20, y: 10)
                    .zIndex(isFrontImageOnTop ? 1 : 0)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFrontImageOnTop.toggle()
                        }
                    }
                }
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 15) {
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
    CaptionView(viewModel: CaptionViewModel(frontImage: UIImage(named: "test1"), backImage: UIImage(named: "test2")), onCancel: {})
}
