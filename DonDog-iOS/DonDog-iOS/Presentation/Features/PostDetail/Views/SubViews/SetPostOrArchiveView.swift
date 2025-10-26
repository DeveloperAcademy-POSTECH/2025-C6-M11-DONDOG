//
//  SetPostOrArchiveView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import SwiftUI

struct SetPostOrArchiveView: View {
    @StateObject var viewModel = SetPostOrArchiveViewModel()
    @State private var shouldScrollToBottom: Bool
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    let postType: PostType
    
    init(postType: PostType, isTextFieldFocused: FocusState<Bool>.Binding) {
        self.postType = postType
        self.isTextFieldFocused = isTextFieldFocused
        shouldScrollToBottom = false
    }
    
    var body: some View {
        if postType == .post {
            ScrollViewReader { proxy in
                ScrollView {
                    // TODO: FeedView에서 선택한 post의 정보 가져와서 파라미터 변경
                    PostDetailContentView(postType: .post, post: PostData.self)
                        .onTapGesture {
                            isTextFieldFocused.wrappedValue = false
                        }
                    
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .onChange(of: shouldScrollToBottom) {
                    if shouldScrollToBottom {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                            shouldScrollToBottom = false
                        }
                    }
                }
            }
            
            CustomCommentEditor(isTextFieldFocused: isTextFieldFocused, shouldScrollToBottom: $shouldScrollToBottom)
        } else {
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { idx, post in
                    ScrollView {
                        CustomPageIndicator(
                            currentIndex: viewModel.currentIndex + 1,
                            totalCount: viewModel.posts.count
                        )
                        .padding(.vertical, 8)
                        
                        PostDetailContentView(postType: .archive, post: post)
                            .tag(idx)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

