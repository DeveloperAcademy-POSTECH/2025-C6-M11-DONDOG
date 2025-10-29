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
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await viewModel.deleteComment(for: comment, in: postId)
                                    shouldBeUpdated = true
                                } catch {
                                    print("댓글 삭제에 실패했습니다: \(error)")
                                }
                            }
                        } label: {
                            Text("삭제")
                            Image(systemName: "trash")
                        }
                    }
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
