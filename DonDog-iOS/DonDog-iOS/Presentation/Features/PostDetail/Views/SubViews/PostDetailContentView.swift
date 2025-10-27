//
//  PostDetailContentView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import SwiftUI

struct PostDetailContentView: View {
    let postType: PostType
    let post: PostData
    
    var body: some View {
        CardView(post: post)
        CommentView(postId: post.postId)
    }
}
