//
//  PostFromFeedView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct PostFromFeedView: View {
    @EnvironmentObject var viewModel: PostDetailViewModel
    
    @State private var shouldScrollToBottom: Bool = false
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    var body: some View {
        if let post = viewModel.posts.first {
            ScrollViewReader { proxy in
                ScrollView {
                    PostDetailContentView(postType: .post, post: post)
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
            
            CustomCommentEditor(
                isTextFieldFocused: isTextFieldFocused,
                shouldScrollToBottom: $shouldScrollToBottom,
                post: post
            )
        } else {
            // TODO: post를 받아오지 못했을 때, 예외 처리 뷰
            EmptyView()
        }
    }
}
