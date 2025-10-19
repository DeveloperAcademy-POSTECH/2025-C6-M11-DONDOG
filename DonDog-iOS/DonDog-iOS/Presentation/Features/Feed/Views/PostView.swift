//
//  PostView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/4/25.
//

import SwiftUI

struct PostView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PostViewModel
    
    @State var text: String = ""
    @State private var showDeleteAlert = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        CustomNavigationBar(
            leadingType: .back(action: { coordinator.pop() }),
            centerType: .title(title: "10월 14일"),
            trailingType: .menu(items: [
                CustomNavMenuItem("삭제하기", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deletePost()
                            await MainActor.run {
                                coordinator.pop()
                            }
                        } catch {
                            print("게시물 삭제 중 오류:", error.localizedDescription)
                        }
                    }
                },
                CustomNavMenuItem("취소") {
                }
            ]),
            navigationColor: .black
        )
        .onTapGesture {
            isTextFieldFocused = false
        }
        
        ScrollViewReader { proxy in
            ZStack(alignment: .topTrailing) {
                Color.white
                    .ignoresSafeArea()
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                
                VStack {
                    ScrollView {
                        VStack {
                            PostContentView(viewModel: viewModel)
                            
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isTextFieldFocused = false
                        }
                    }
                    
                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 56)
                            .shadow(color: Color.black.opacity(0.05),
                                    radius: 5,
                                    x: 0,
                                    y: -2)
                        
                        HStack(spacing: 4) {
                            GrowingTextEditor(
                                text: $text,
                                minHeight: 40,
                                maxHeight: 73,
                                isFocused: _isTextFieldFocused
                            )
                            
                            Button {
                                Task {
                                    isTextFieldFocused = false
                                    let currentText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !currentText.isEmpty else { return }
                                    await viewModel.saveComment(of: currentText)
                                    text = ""
                                    withAnimation(.easeOut) {
                                        proxy.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                            } label: {
                                Image(systemName: "paperplane.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(isTextFieldFocused && !text.isEmpty ? Color.ddPrimaryBlue : Color.ddSecondaryBlue)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .animation(.spring(), value: text)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                    }
                }
                
                Image(uiImage: viewModel.stickerImage)
                    .resizable()
                    .frame(width: 76, height: 94)
                    .padding(.top, 28)
            }
        }
        .navigationBarBackButtonHidden()
    }
}
