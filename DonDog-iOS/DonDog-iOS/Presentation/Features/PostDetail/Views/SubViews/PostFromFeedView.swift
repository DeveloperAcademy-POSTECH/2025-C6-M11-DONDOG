//
//  PostFromFeedView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct PostFromFeedView: View {
    @State private var shouldScrollToBottom: Bool = false
    var isTextFieldFocused: FocusState<Bool>.Binding
    
    var body: some View {
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
    }
}
