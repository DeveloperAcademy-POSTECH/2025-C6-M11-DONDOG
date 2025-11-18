//
//  CustomAlert.swift
//  DonDog-iOS
//
//  Created by 조유진 on 11/14/25.
//

import SwiftUI

struct CustomAlert: View {
    @Binding var isPresented: Bool
    
    let title: String
    let message: String?
    let confirmTitle: String
    let cancelTitle: String?
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color.ppBlack
                .opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.ppSubPrime15)
                        .padding(.top, 8)
                    
                    VStack(spacing: 2) {
                        // 타이틀
                        Text(title)
                            .font(.subtitleMedium18)
                            .foregroundStyle(.ppBlack)
                            .multilineTextAlignment(.center)
                        
                        // 컨텐츠
                        if let message {
                            Text(message)
                                .font(.captionRegular14)
                                .foregroundStyle(.ppGray600)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .padding(.top, 10)
                
                // 버튼
                HStack(spacing: 12) {
                    if let cancelTitle, let onCancel {
                        Button {
                            isPresented = false
                            onCancel()
                        } label: {
                            Text(cancelTitle)
                                .font(.bodyRegular16)
                                .frame(maxWidth: .infinity, minHeight: 40, alignment: .center)
                                .background(.ppSubPrime15)
                                .foregroundColor(.ppPrime50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    Button {
                        isPresented = false
                        onConfirm()
                    } label: {
                        Text(confirmTitle)
                            .font(.bodyRegular16)
                            .frame(maxWidth: .infinity, minHeight: 40, alignment: .center)
                            .background(.ppSubPrime)
                            .foregroundColor(.ppWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(.ppWhite)
            .frame(maxWidth: 270, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }
}

struct CustomAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let confirmTitle: String
    let cancelTitle: String?
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                CustomAlert(
                    isPresented: $isPresented,
                    title: title,
                    message: message,
                    confirmTitle: confirmTitle,
                    cancelTitle: cancelTitle,
                    onConfirm: onConfirm,
                    onCancel: onCancel
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity
                            .combined(with: .scale(scale: 1.05)),
                        removal: .opacity
                            .combined(with: .scale(scale: 1.0))
                    )
                )
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmTitle: String = "확인",
        cancelTitle: String? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(
            CustomAlertModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                cancelTitle: cancelTitle,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
        )
    }
}

#Preview("CustomAlert View") {
    ZStack {
        CustomAlert(
            isPresented: .constant(true),
            title: "정말 삭제하시겠어요?",
            message: "한 번 삭제한 게시물은 되돌릴 수 없어요",
            confirmTitle: "삭제하기",
            cancelTitle: "취소",
            onConfirm: {},
            onCancel: {}
        )
    }
}

#Preview("CustomAlert Withdraw View") {
    @Previewable @State var showAlert = true
    
    ZStack {
        Color.ppWhite
            .ignoresSafeArea()
        
        Button("삭제 테스트") {
            showAlert = true
        }
    }
    .customAlert(
        isPresented: $showAlert,
        title: "가입한 전화번호가 아니에요",
        message: "번호를 다시 확인해 주세요",
        confirmTitle: "확인",
        onConfirm: {
            // 삭제 로직
        }
    )
}

#Preview("CustomAlert Modifier") {
    @Previewable @State var showAlert = true
    
    ZStack {
        Color.ppWhite
            .ignoresSafeArea()
        
        Button("삭제 테스트") {
            showAlert = true
        }
    }
    .customAlert(
        isPresented: $showAlert,
        title: "역할 변경 시, 만든 스티커가\n초기화됩니다. 변경하시겠어요?",
        confirmTitle: "삭제하기",
        cancelTitle: "취소",
        onConfirm: {
            // 삭제 로직
        },
        onCancel: {
            // 취소 로직
        }
    )
}
