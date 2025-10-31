//
//  OriginalCommentView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/17/25.
//

import SwiftUI

// 새로 생긴 PostDetail 안의 CommentView와 이름이 중복되는데, PostDetail pr 승인 후에는 삭제될 파일이라 임시로 변경해두었습니다.
struct OriginalCommentView: View {
    let comment: Comment
    @State private var authorName: String = "익명"
    @StateObject var viewModel: PostViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(authorName)
                    .font(.captionMedium14)
                Text(DateUtils.relativeTimeString(from: comment.createdAt))
                    .font(.captionRegular13)
                    .foregroundStyle(Color.ddGray600)
            }
            Text(comment.text)
                .font(.captionRegular14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .task {
            authorName = await viewModel.fetchAuthorName(of: comment.uid) ?? "익명"
        }
    }
}
