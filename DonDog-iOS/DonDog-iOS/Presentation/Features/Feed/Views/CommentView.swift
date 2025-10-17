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
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 20) {
                Text(authorName)
                    .font(.system(size: 18))
                    .foregroundStyle(.gray)
                Text(DataUtils.formatDate(comment.createdAt, format: "HH:mm"))
                    .font(.system(size: 18))
                    .foregroundStyle(.gray)
            }
            Text(comment.text)
                .font(.system(size: 18))
                .foregroundStyle(.gray)
        }
        .padding(.vertical, 5)
        .task {
            authorName = await viewModel.fetchAuthorName(of: comment.uid) ?? "익명"
        }
    }
}
