//
//  PostFromFeedView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct PostFromFeedView: View {
    @EnvironmentObject var viewModel: PostDetailViewModel
    
    @State private var newCommentSaved: Bool = false
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    var body: some View {
        if let post = viewModel.posts.first {
            ScrollViewReader { proxy in
                ScrollView {
                    PostContentsView(post: post)
                    
                    // TODO: update 방식 변경 필요 여부 확인
                    CommentView(postId: post.postId, shouldBeUpdated: $newCommentSaved)
                    
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .onChange(of: newCommentSaved) { _, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                            
                            newCommentSaved = false
                        }
                    }
                }
                .onTapGesture {
                    isTextFieldFocused.wrappedValue = false
                }
                
                CustomCommentEditor(
                    isTextFieldFocused: isTextFieldFocused,
                    newCommentSaved: $newCommentSaved,
                    post: post
                )
            }
        } else {
            // TODO: post를 받아오지 못했을 때, 예외 처리 뷰
            EmptyView()
        }
    }
}
