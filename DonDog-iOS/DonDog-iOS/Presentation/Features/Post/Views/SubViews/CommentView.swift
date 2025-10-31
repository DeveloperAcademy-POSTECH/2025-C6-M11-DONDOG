//
//  CommentView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI
import FirebaseCore

struct CommentView: View {
    @StateObject var viewModel = CommentViewModel()
    let postId: String
    @Binding var shouldBeUpdated: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.comments, id: \.createdAt) { comment in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(viewModel.name)
                            .font(.captionMedium14)
                        Text(DateUtils.relativeTimeString(from: comment.createdAt.dateValue()))
                            .font(.captionRegular13)
                            .foregroundStyle(Color.ddGray600)
                    }
                    Text(comment.text)
                        .font(.captionRegular14)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onAppear {
                    viewModel.fetchUserName(of: comment.authorId)
                }
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
