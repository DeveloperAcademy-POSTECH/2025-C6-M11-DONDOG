//
//  PostFrameView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/30/25.
//

import SwiftUI
import FirebaseCore

struct PostFrameView: View {
    @Binding var currentIndex: Int
    @StateObject var viewModel: PostViewModel
    @State private var shouldBeUpdated: Bool = false
    
    var isTextFieldFocused: FocusState<Bool>.Binding
    let postType: PostType
    
    var body: some View {
        if postType == .post {
            if let post = viewModel.posts.first {
                ScrollViewReader { proxy in
                    ScrollView {
                        PostContentsView(post: post)
                        
                        // TODO: update 방식 변경 필요 여부 확인
                        CommentView(postId: post.postId, shouldBeUpdated: $shouldBeUpdated)
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .onChange(of: shouldBeUpdated) { _, newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                                
                                shouldBeUpdated = false
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused.wrappedValue = false
                    }
                    
                    CustomCommentEditor(
                        isTextFieldFocused: isTextFieldFocused,
                        newCommentSaved: $shouldBeUpdated,
                        post: post
                    )
                }
            } else {
                // TODO: post를 받아오지 못했을 때, 예외 처리 뷰
                EmptyView()
            }
        } else {
            let posts = viewModel.posts
            
            TabView(selection: $currentIndex) {
                ForEach(Array(posts.enumerated()), id: \.offset) { idx, post in
                    ScrollView {
                        CustomPageIndicator(
                            currentIndex: currentIndex + 1,
                            totalCount: posts.count
                        )
                        .padding(.vertical, 8)
                        
                        VStack(spacing: 0) {
                            PostContentsView(post: post)
                            
                            // TODO: update 방식 변경 필요 여부 확인
                            CommentView(postId: post.postId, shouldBeUpdated: $shouldBeUpdated)
                        }
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
