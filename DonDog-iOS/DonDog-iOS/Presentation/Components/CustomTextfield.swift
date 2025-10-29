//
//  CustomTextfield.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/14/25.
//

import SwiftUI

struct CustomTextField: View {
    var title: String?
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var onCommit: (() -> Void)?
    var errorMessage: String?
    var errorText: Binding<String?>?
    var showExternalError: Binding<Bool>?
    var softMaxLength: Int?
    var softMaxErrorText: String?
    var isDisabled: Bool = false

    @FocusState private var isFocused: Bool
    @State private var localValidationError: String?
    @State private var suppressExternalError: Bool = false

    private var externalErrorMessage: String? {
        if suppressExternalError { return nil }
        if let gate = showExternalError?.wrappedValue, gate == false { return nil }
        if let bound = errorText?.wrappedValue, !bound.isEmpty { return bound }
        if let msg = errorMessage, !msg.isEmpty { return msg }
        return nil
    }

    private var hasError: Bool {
        if let msg = localValidationError, !msg.isEmpty { return true }
        return externalErrorMessage != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.subtitleMedium18)
            }
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .font(.subtitleMedium18)
                                .foregroundColor(Color.ddGray500)
                                .allowsHitTesting(false)
                        }
                        HStack {
                            TextField("", text: $text)
                                .disabled(isDisabled)
                                .font(.bodyRegular18)
                                .foregroundColor(Color.ddBlack)
                                .keyboardType(keyboard)
                                .focused($isFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    suppressExternalError = false
                                    onCommit?()
                                    isFocused = false
                                }
                                .onChange(of: text) { _, newValue in
                                    showExternalError?.wrappedValue = false
                                    suppressExternalError = true
                                    if hasError {
                                        localValidationError = nil
                                        errorText?.wrappedValue = nil
                                    }
                                    var value = newValue.filter { !$0.isWhitespace }

                                    if contentType == .telephoneNumber {
                                        let digits = value.filter { $0.isNumber }
                                        let limited = String(digits.prefix(11))
                                        var formatted = ""
                                        for (i, ch) in limited.enumerated() {
                                            if i == 3 || i == 7 { formatted.append("-") }
                                            formatted.append(ch)
                                        }
                                        value = formatted
                                    } else if keyboard == .numberPad {
                                        value = value.filter { $0.isNumber }
                                    }

                                    if let max = softMaxLength {
                                        if value.count > max {
                                            localValidationError = softMaxErrorText ?? "최대 \(max)자까지 입력할 수 있어요"
                                        } else {
                                            localValidationError = nil
                                        }
                                    }

                                    if value != text {
                                        text = value
                                    }
                                }
                                .onChange(of: isFocused) { _, focused in
                                    if !focused {
                                        suppressExternalError = false
                                        onCommit?()
                                    }
                                }
                                .textContentType(contentType)

                            if let max = softMaxLength {
                                Text("\(text.count)/\(max)")
                                    .font(.captionRegular13)
                                    .foregroundColor(hasError ? Color.ddAlert : Color.ddGray500)
                            }
                        }

                    }
                }

                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(
                        hasError
                        ? Color.ddAlert : ((isFocused && !text.isEmpty) ? Color.ddPrimaryBlue : Color.ddSecondaryBlue)
                    )

                if hasError, let message = (localValidationError ?? externalErrorMessage) {
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

struct PreviewUnderlineTextFieldWrapper: View {
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
                placeholder: "010-1234-5678",
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
    PreviewUnderlineTextFieldWrapper()
}
