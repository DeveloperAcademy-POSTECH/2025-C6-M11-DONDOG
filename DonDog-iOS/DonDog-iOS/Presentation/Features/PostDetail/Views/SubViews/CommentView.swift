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
    @Binding var shouldBeUpdated: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.comments, id: \.createdAt) { comment in
                CommentRow(comment: comment)
            }
        }
        .task(id: shouldBeUpdated) {
            await viewModel.fetchComments(postId: postId)
            
            DispatchQueue.main.async {
                shouldBeUpdated = false
            }
        }
    }
}
