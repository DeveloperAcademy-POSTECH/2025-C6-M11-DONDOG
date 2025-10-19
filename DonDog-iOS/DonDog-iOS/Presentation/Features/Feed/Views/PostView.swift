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
                    
                    HStack {
                        GrowingTextEditor(
                            text: $text,
                            minHeight: 52,
                            maxHeight: 73,
                            isFocused: _isTextFieldFocused
                        )
                        
                        Button {
                            Task {
                                let currentText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !currentText.isEmpty else { return }
                                await viewModel.saveComment(of: currentText)
                                text = ""
                                isTextFieldFocused = false
                                withAnimation(.easeOut) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.white)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 8)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.spring(), value: text)
                        .padding(.trailing, 11)
                    }
                }
                
                Image(uiImage: viewModel.stickerImage)
                    .resizable()
                    .frame(width: 76, height: 94)
                    .padding(.top, 28)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .toolbar {
                if viewModel.uid == viewModel.currentUser {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Label("삭제하기", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
            .alert("게시글을 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) {
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
                }
                Button("취소", role: .cancel) { }
            }
        }
    }
}
