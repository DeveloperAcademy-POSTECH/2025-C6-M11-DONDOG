//
//  CustomTextfield.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import SwiftUI

struct CustomTextField: View {
    var title: String?
    var prefix: String?
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var onCommit: (() -> Void)? = nil
    var errorMessage: String? = nil
    
    private var hasError: Bool {
        errorMessage != nil && !errorMessage!.isEmpty
    }

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.subtitleMedium18)
            }
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    HStack {
                        if let prefix = prefix {
                            Text(prefix)
                                .font(.titleBold18)
                                .foregroundStyle(Color.ddPrimaryBlue)
                                .padding(.trailing, 10)
                        }
                    }
                    
                    ZStack(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .font(.subtitleMedium18)
                                .foregroundColor(Color.ddGray500)
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $text)
                            .font(.bodyRegular18)
                            .foregroundColor(Color.ddBlack)
                            .keyboardType(keyboard)
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                onCommit?()
                                isFocused = false
                            }
                            .onChange(of: text) { newValue in
                                var value = newValue.filter { !$0.isWhitespace }
                                
                                if contentType == .telephoneNumber {
                                    let digits = value.filter { $0.isNumber }
                                    let limited = String(digits.prefix(10))
                                    var formatted = ""
                                    for (i, ch) in limited.enumerated() {
                                        if i == 2 || i == 6 { formatted.append("-") }
                                        formatted.append(ch)
                                    }
                                    value = formatted
                                } else if keyboard == .numberPad {
                                    value = value.filter { $0.isNumber }
                                }

                                if value != text {
                                    text = value
                                }
                            }
                            .onChange(of: isFocused) { focused in
                                if !focused {
                                    onCommit?()
                                }
                            }
                            .textContentType(contentType)
                    }
                }
                
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(
                        hasError ? Color.ddAlert : (isFocused ? Color.ddPrimaryBlue : Color.ddSecondaryBlue)
                    )
                
                if hasError, let message = errorMessage {
                    HStack(spacing: 0) {
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14)
                            .padding(.trailing, 4)
                        Text(message)
                            .font(.captionRegular13)
                        Spacer()
                    }
                    .foregroundColor(Color.ddAlert)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
                isFocused = true
        }
    }
}

struct Preview_UnderlineTextFieldWrapper: View {
    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var code2: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            CustomTextField(
                title: "휴대폰 번호",
                placeholder: "휴대폰 번호를 입력해 주세요",
                text: $phone,
                keyboard: .numberPad,
                contentType: .telephoneNumber,
                errorMessage: "형식이 올바르지 않습니다."
            )
            CustomTextField(
                title: "휴대폰 번호",
                placeholder: "휴대폰 번호를 입력해 주세요",
                text: $phone,
                keyboard: .numberPad,
                contentType: .telephoneNumber
            )
            CustomTextField(
                title: "인증번호를 입력해 주세요",
                prefix: "+82",
                placeholder: "10-1234-5678",
                text: $code,
                keyboard: .default,
                contentType: nil
            )
            CustomTextField(
                title: nil,
                placeholder: "인증번호를 입력해 주세요",
                text: $code2,
                keyboard: .default,
                contentType: nil
            )
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    Preview_UnderlineTextFieldWrapper()
}
