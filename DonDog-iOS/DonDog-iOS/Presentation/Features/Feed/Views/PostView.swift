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
    
    private var titleString: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.timeZone = TimeZone(identifier: "Asia/Seoul")
        fmt.dateFormat = "MM월 dd일"
        return fmt.string(from: viewModel.createdAt)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                CustomNavigationBar(
                    leadingType: .back(action: { coordinator.pop() }),
                    centerType: .title(title: titleString),
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
        } message: {
            Text("삭제한 사진은 되돌릴 수 없어요")
        }
        .alert("댓글을 삭제하시겠어요?", isPresented: .constant(viewModel.commentToDelete != nil), actions: {
            Button("삭제", role: .destructive) {
                if let comment = viewModel.commentToDelete {
                    Task {
                        await viewModel.deleteComment(of: comment)
                        viewModel.commentToDelete = nil
                    }
                }
            }
            Button("취소", role: .cancel) {
                viewModel.commentToDelete = nil
            }
        })
    }
}

