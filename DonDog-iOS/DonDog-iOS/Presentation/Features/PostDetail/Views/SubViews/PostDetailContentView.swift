//
//  PostDetailContentView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import SwiftUI

struct PostDetailContentView: View {
    let postType: PostType
    // TODO: PostView와 ArchiveDetailView의 공통된 데이터 구조체로 변경
    let post: Any
    
    var body: some View {
        CardView(post: post)
        // TODO: 실제 postId 전달
        CommentView(postId: "post.id")
    }
}
