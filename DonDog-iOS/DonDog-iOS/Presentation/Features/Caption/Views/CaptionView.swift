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
    var onReturnToHome: () -> Void
    @State private var isShowCaptionEditor: Bool = false
    @FocusState private var isCaptionFocused: Bool
    @State private var isFrontImageOnTop = true
    
    var body: some View {
        ZStack(alignment: .center){
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
                .padding(20)
                    if let frontImage = viewModel.frontImage, let backImage = viewModel.backImage {
                        HStack{
                            Spacer()
                            PolaroidSetView(frontImage: .uiImage(frontImage), backImage: .uiImage(backImage), nickname: "", createdAt: "", caption: nil,  selectedStickerEmotion: nil, stickerImage: nil, isMyPost: true)
                                .allowsHitTesting(true)
                                .padding(.trailing, 30)
                        }
                        .padding(.top, 103)
                    }
                
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
                        .onChange(of: viewModel.caption) { oldValue, newValue in
                            if newValue.count > 8 {
                                viewModel.caption = String(newValue.prefix(8))
                            }
                        }
                        .onSubmit {
                            isShowCaptionEditor = false
                            isCaptionFocused = false
                        }
                }
                .hapticFeedback(.medium)
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 20)
                
                Button{
                    onReturnToHome()
                    viewModel.uploadPost()
                }label: {
                        Text("업로드")
                            .font(.bodyRegular18)
                            .foregroundColor(.ddWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                }
                .background(.ddPrimaryBlue)
                .cornerRadius(12)
                .disabled(viewModel.isUploading)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .hapticFeedback(.medium)
            }
            //MARK: -- 캡션 남길 때
            if isShowCaptionEditor {
                ZStack{
                    Color.black
                        .opacity(0.75)
                    VStack(spacing: 4){
                        Spacer()
                        Text(viewModel.caption.isEmpty ? "눌러서 캡션 남기기..." : viewModel.caption)
                            .font(.subtitleMedium20)
                            .foregroundStyle(viewModel.caption.isEmpty ? .ddGray600 : .ddWhite)
                        if !viewModel.caption.isEmpty {
                            Text("\(viewModel.caption.count)/8")
                                .font(.captionRegular13)
                                .foregroundStyle(.ddSecondaryBlue)
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
}
