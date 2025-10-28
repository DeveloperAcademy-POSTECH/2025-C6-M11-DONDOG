//
//  CustomCommentEditor.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct CustomCommentEditor: View {
    @StateObject private var viewModel = CustomCommentEditorViewModel()
    @Binding var shouldScrollToBottom: Bool
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    @State private var isLineChanged: Bool
    @State private var isTextSaveable: Bool;
    
    @State var text = ""
    
    init(isTextFieldFocused: FocusState<Bool>.Binding, shouldScrollToBottom: Binding<Bool>) {
        self.isTextFieldFocused = isTextFieldFocused
        self._shouldScrollToBottom = shouldScrollToBottom
        isLineChanged = false
        isTextSaveable = false
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.ddWhite
                .overlay(
                    LinearGradient(
                        colors: [.ddBlack.opacity(0.05), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 5),
                    alignment: .top
                )
                .frame(height: isLineChanged ? 92 : 59)
            
            HStack(spacing: 4) {
                TextField("댓글을 입력해 주세요...", text: $text, axis: .vertical)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .focused(isTextFieldFocused)
                    .background(
                        RoundedRectangle(cornerRadius: isLineChanged ? 24 : 74)
                            .fill(.ddGray100)
                            .frame(height: isLineChanged ? 73 : 40)
                    )
                    .onChange(of: text) { _, _ in
                        checkIfLineChanged()
                        checkIfTextSaveable()
                    }
                    .frame(height: isLineChanged ? 73 : 40)
                
                Button {
                    Task {
                        isTextFieldFocused.wrappedValue = false
                        
                        if isTextSaveable {
                            await viewModel.saveComment()
                            text = ""
                            shouldScrollToBottom = true
                        }
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(text.isEmpty ? .ddSecondaryBlue : .ddPrimaryBlue)
                }
                .animation(.spring(), value: text)
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 20)
        }
    }
    
    private func checkIfLineChanged() {
        if text.count > 30 {
            isLineChanged = true
        } else {
            isLineChanged = false
        }
    }
    
    private func checkIfTextSaveable() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            isTextSaveable = false
        } else {
            isTextSaveable = true
        }
    }
}
