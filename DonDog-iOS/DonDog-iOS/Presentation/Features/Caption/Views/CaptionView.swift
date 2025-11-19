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
    @State private var isShowCancelAlert: Bool = false
    @FocusState private var isCaptionFocused: Bool
    @StateObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .center) {
                VStack(spacing: 0) {
                    CustomNavigationBar(leadingType: .none, centerType: .timeTitle(title: DateUtils.string(from: .now, format: .monthDay), timeImage: DateUtils.isATime(date: .now) ? "sun.max.fill" : "moon.fill"), trailingType: .close(action: {isShowCancelAlert = true}), navigationColor: .black)
                        .padding(.horizontal, 16)
                    if let frontImage = viewModel.frontImage, let backImage = viewModel.backImage {
                        ZStack {
                            TabView(selection: $viewModel.currentIndex) {
                                Image(uiImage: frontImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .padding(.horizontal, 20)
                                    .tag(0)
                                
                                Image(uiImage: backImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .padding(.horizontal, 20)
                                    .tag(1)
                                
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .tint(.ppPrime)
                            .onAppear {
                                UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.ppPrime)
                                UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.ppPrime50)
                            }
                        }
                        .frame(height: max(470 - keyboard.keyboardHeight, 366))
                        .animation(.easeInOut(duration: 0.3), value: keyboard.keyboardHeight)
                        .padding(.vertical, 8)
                        .onTapGesture {
                            isCaptionFocused = false
                        }
                    }
                    
                    VStack(alignment: .center, spacing: 0) {
                        HStack {
                            Spacer()
                            ZStack(alignment: .center) {
                                TextField(DateUtils.isATime(date: .now) ? "오늘 나의 오전을 설명해 주세요..." : "오늘 나의 오후를 설명해 주세요...", text: $viewModel.caption)
                                    .font(.subtitleMedium18)
                                    .focused($isCaptionFocused)
                                    .multilineTextAlignment(.center)
                                    .tint(.ppPrime)
                                    .submitLabel(.done)
                                    .onChange(of: viewModel.caption) { _, newValue in
                                        if newValue.count > 15 {
                                            viewModel.caption = String(newValue.prefix(15))
                                        }
                                    }
                                    .onSubmit {
                                        isCaptionFocused = false
                                    }
                            }
                            Spacer()
                            if !viewModel.caption.isEmpty && isCaptionFocused {
                                Text("\(viewModel.caption.count)/15")
                                    .font(.captionRegular13)
                                    .foregroundStyle(.ppGray400)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .hapticFeedback(.medium)
                    .background {
                        if isCaptionFocused {
                            Rectangle()
                                .foregroundStyle(.ppGray200)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        onReturnToHome()
                        viewModel.uploadPost()
                    } label: {
                        Text("업로드하기")
                            .font(.bodyMedium16)
                            .foregroundColor(.ppWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .background(.ppPrime)
                    .cornerRadius(12)
                    .disabled(viewModel.isUploading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .hapticFeedback(.heavy)
                }
            }
            .background {
                Color.ppWhite
                    .ignoresSafeArea()
                    .onTapGesture {
                        isCaptionFocused = false
                    }
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            isCaptionFocused = true
        }
        .customAlert(isPresented: $isShowCancelAlert, title: "나가시겠어요?", message: "지금까지 찍은 사진은 사라져요", confirmTitle: "나가기", cancelTitle: "취소", onConfirm: { onReturnToHome() }, onCancel: {})
        
    }
}

#Preview {
    CaptionView(viewModel: CaptionViewModel(frontImage: UIImage(named: "front"), backImage: UIImage()), onCancel: {}, onReturnToHome: {})
}
