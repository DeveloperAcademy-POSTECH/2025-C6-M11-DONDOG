//
//  CommentRow.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CommentRow: View {
    @StateObject var viewModel = CommentRowViewModel()
    let comment: CommentData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(viewModel.name)
                    .font(.captionMedium14)
                Text(DateUtils.relativeTimeString(from: viewModel.createdAt, for: "MM월 dd일 HH:mm"))
                    .font(.captionRegular13)
                    .foregroundStyle(Color.ddGray600)
            }
            Text(viewModel.text)
                .font(.captionRegular14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onAppear {
            viewModel.setCommentData(comment: comment)
        }
    }
}
