//
//  DetailContentView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/17/25.
//

import SwiftUI

struct DetailContentView: View {
    @StateObject var viewModel: ArchiveViewModel

    let post: ArchivePost
    let userNameByUid: [String: String]
    let onDelete: ((Comment) async -> Void)?

    var body: some View {
        ScrollView {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    DetailPhotoView(post: post)
                    DetailCaptionView(post: post, userNameByUid: userNameByUid)
                }.padding(.vertical, 8)
                
                if let sticker = viewModel.borderedStickers[post.id] {
                    Image(uiImage: sticker)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 138)
                }
            }
            .background(.ddWhite)
            .shadow(color: .ddBlack.opacity(0.05), radius: 2.5, x: 0, y: 3)
            .onAppear {
                if let sId = post.stickerPostId,
                   !sId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   sId.lowercased() != "null",
                   viewModel.borderedStickers[post.id] == nil {
                    viewModel.getStickerData(stickerPostId: sId, for: post.id)
                }
            }
            DetailCommentsView(
                comments: post.comments.map { ($0, userNameByUid[$0.uid] ?? "익명") },
                onDelete: onDelete
            )
        }
    }
}
