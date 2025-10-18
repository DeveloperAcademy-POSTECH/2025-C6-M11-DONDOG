//
//  CommentView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/17/25.
//

import SwiftUI

struct CommentView: View {
    let comment: Comment
    @State private var authorName: String = "익명"
    @StateObject var viewModel: PostViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 20) {
                Text(authorName)
                    .font(.system(size: 14))
                Text(DataUtils.formatTimeAgo(from: comment.createdAt))
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
            }
            Text(comment.text)
                .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .task {
            authorName = await viewModel.fetchAuthorName(of: comment.uid) ?? "익명"
        }
    }
}
