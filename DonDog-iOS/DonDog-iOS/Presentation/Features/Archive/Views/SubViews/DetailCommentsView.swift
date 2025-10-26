//
//  DetailCommentsView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/19/25.
//

import SwiftUI

struct DetailCommentRow: View {
    let comment: Comment
    let authorName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(authorName)
                    .font(.captionMedium14)
                    .foregroundStyle(.ddBlack)
                Text(DateUtils.relativeTimeString(from: comment.createdAt, for: "MM월 dd일 HH:mm"))
                    .font(.captionRegular13)
                    .foregroundStyle(.ddGray600)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(comment.text)
                .font(.captionRegular14)
                .foregroundStyle(.ddBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct DetailCommentsView: View {
    let comments: [(Comment, String)]
    let onDelete: ((Comment) async -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(comments, id: \.0.id) { (comment, authorName) in
                DetailCommentRow(comment: comment, authorName: authorName)
                    .contextMenu {
                        if let onDelete {
                            Button(role: .destructive) {
                                Task { await onDelete(comment) }
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
