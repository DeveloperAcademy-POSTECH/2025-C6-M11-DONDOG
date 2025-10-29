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
    @FocusState private var isTextFieldFocused: Bool
    @State private var textLineCount: Int = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) { 
                CustomNavigationBar(
                    leadingType: .back(action: { coordinator.pop() }),
                    centerType: .title(title: DateUtils.string(from: viewModel.createdAt, format: .monthDay)),
                    trailingType: .menu(items: [
                        CustomNavMenuItem("삭제하기", role: .destructive) {
                            viewModel.handleDeleteRequest()
                        },
                    ]),
                    navigationColor: .black
                )
                .padding(.horizontal, 20)
                .onTapGesture {
                    isTextFieldFocused = false
                }
                
                ScrollViewReader { proxy in
                    ZStack(alignment: .topTrailing) {
                        Color.ddWhite
                            .ignoresSafeArea()
                            .onTapGesture {
                                isTextFieldFocused = false
                            }
                        
                        VStack(spacing: 0) {
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
                            
                            ZStack(alignment: .bottom) {
                                Color.clear
                                    .overlay(
                                        LinearGradient(
                                            colors: [Color.ddBlack.opacity(0.05), .clear],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                        .frame(height: 5),
                                        alignment: .top
                                    )
                                    .frame(height: self.textLineCount > 1 || self.text.count > 20 ? 92 : 59)
                                
                                HStack(spacing: 4) {
                                    TextField("댓글을 입력해 주세요...", text: $text, axis: .vertical)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .scrollContentBackground(.hidden)
                                        .focused($isTextFieldFocused)
                                        .background(
                                            RoundedRectangle(cornerRadius: (self.textLineCount > 1 || self.text.count > 20) ? 24 : 74)
                                                .fill(Color.ddGray100)
                                                .frame(height: (self.textLineCount > 1 || self.text.count > 20) ? 73 : 40)
                                        )
                                        .onChange(of: text) { _, _ in
                                            self.textLineCount = text.components(separatedBy: "\n").count
                                        }
                                        .frame(height: (self.textLineCount > 1 || self.text.count > 20) ? 73 : 40)

                                    
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
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundStyle(isTextFieldFocused && !text.isEmpty ? Color.ddPrimaryBlue : Color.ddSecondaryBlue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .animation(.spring(), value: text)
                                }
                                .padding(.bottom, 7)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }
            
            if viewModel.showUnauthorizedAlert {
                VStack {
                    Spacer()
                    ToastView(toastText: "본인이 작성한 글만 삭제할 수 있어요")
                        .padding(.bottom, 80)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    viewModel.showUnauthorizedAlert = false
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).animation(.spring()),
                            removal: .opacity.animation(.easeOut(duration: 0.7))
                        ))
                }
            }
        }
        .navigationBarBackButtonHidden()
        .alert("사진을 삭제하시겠어요?", isPresented: $viewModel.showDeleteConfirmAlert) {
            Button("확인", role: .destructive) {
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
        } message: { Text("삭제한 사진은 되돌릴 수 없어요") }
            .alert("댓글을 삭제하시겠어요?", isPresented: .constant(viewModel.commentToDelete != nil), actions: {
                Button("삭제", role: .destructive) {
                    if let comment = viewModel.commentToDelete {
                        Task {
                            viewModel.deleteComment(of: comment)
                            viewModel.commentToDelete = nil
                        }
                    }
                }
                Button("취소", role: .cancel) { viewModel.commentToDelete = nil }
            })
    }
}
