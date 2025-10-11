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
    
    @State var content: String = ""
    @State private var showDeleteAlert = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {
                Text(viewModel.authorName)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.bottom, 4)
                Text(DataUtils.formatDate(viewModel.createdAt, format: "HH:mm"))
                    .font(.system(size: 16, weight: .regular))
                    .padding(.bottom, 19)
                
                PostContentView(viewModel: viewModel)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 16)
                HStack {
                    TextField("댓글을 입력해 주세요", text: $content)
                        .padding(.leading, 20)
                        .focused($isTextFieldFocused)
                    if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            viewModel.saveComment(of: content)
                            content = ""
                            isTextFieldFocused = false
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
                        .animation(.spring(), value: content)
                        .padding(.trailing, 11)
                    }
                }
                .frame(height: 52)
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .padding(.bottom, 12)
            }
            
            Image(uiImage: viewModel.stickerImage)
                .resizable()
                .frame(width: 76, height: 94)
                .padding(.top, 28)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .toolbar {
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
        .alert("게시글을 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                // deletePost()
            }
            Button("취소", role: .cancel) { }
        }
    }
}
