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
                                guard keyboard == .numberPad else { return }
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    text = filtered
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
                        isFocused ? Color.ddPrimaryBlue :
                        Color.ddSecondaryBlue
                    )
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
