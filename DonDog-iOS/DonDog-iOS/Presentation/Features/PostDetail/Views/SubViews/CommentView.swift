//
//  CommentView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct CommentView: View {
    @StateObject var viewModel = CommentViewModel()
    let postId: String
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.comments, id: \.createdAt) { comment in
                CommentRow(comment: comment)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchComments(postId: postId)
            }
        }
    }
}
