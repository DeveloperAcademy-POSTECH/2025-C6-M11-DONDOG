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
    var onUploadComplete: () -> Void
    @State private var isShowCaptionEditor: Bool = false
    @FocusState private var isCaptionFocused: Bool
    @State private var isFrontImageOnTop = true
    
    var body: some View {
        ZStack{
            VStack(spacing: 20) {
                // 상단 타이틀
                HStack {
                    Spacer()
                    Button(action: {
                        onCancel()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
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
                    Text(viewModel.caption.isEmpty ? "눌러서 캡션 남기기..." : viewModel.caption)
                        .onTapGesture {
                            isShowCaptionEditor = true
                            isCaptionFocused = true
                        }
                        .padding(.vertical, 8)
                        .font(.subtitleMedium20)
                        .foregroundStyle(viewModel.caption.isEmpty ? .ddGray600 : .ddBlack)
                        .opacity(isShowCaptionEditor ? 0 : 1)
                    
                    TextField("", text: $viewModel.caption)
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        .focused($isCaptionFocused)
                        .submitLabel(.done)
                        .onChange(of: viewModel.caption) { newValue in
                            if newValue.count > 8 {
                                viewModel.caption = String(newValue.prefix(8))
                            }
                        }
                        .onSubmit {
                            isShowCaptionEditor = false
                            isCaptionFocused = false
                        }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button{
                    viewModel.uploadPost()
                }label: {
                    if viewModel.isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("업로드")
                            .font(.bodyRegular18)
                            .foregroundColor(.ddWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                }
                .background(viewModel.isUploading ? .ddGray600 : .ddPrimaryBlue)
                .cornerRadius(12)
                .disabled(viewModel.isUploading)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .onChange(of: viewModel.isUploading) { newValue in
                    if newValue == false{
                        onUploadComplete()
                    }
                }
            }
            //MARK: -- 캡션 남길 때
            if isShowCaptionEditor {
                ZStack{
                    Color.black
                        .opacity(0.75)
                    VStack{
                        Spacer()
                        Text(viewModel.caption.isEmpty ? "눌러서 캡션 남기기..." : viewModel.caption)
                            .font(.subtitleMedium20)
                            .foregroundStyle(viewModel.caption.isEmpty ? .ddGray600 : .ddWhite)
                        if !viewModel.caption.isEmpty {
                            Text("\(viewModel.caption.count)/8")
                        }
                        Spacer()
                    }
                }.ignoresSafeArea()
                    .onTapGesture {
                        isShowCaptionEditor = false
                        isCaptionFocused = false
                        
                    }
            }
        }
        
        .background{
            ZStack{
                Color.ddWhite
                LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                    .opacity(0.35)
            }.ignoresSafeArea()
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
    CaptionView(viewModel: CaptionViewModel(frontImage: UIImage(named: "test1"), backImage: UIImage(named: "test2")), onCancel: {}, onUploadComplete: {})
}
