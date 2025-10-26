//
//  CardView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct CardView: View {
    // TODO: PostView와 ArchiveDetailView의 공통된 데이터 구조체로 변경
    let post: Any
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // CardPhotoView(front: viewModel.frontURL, back: viewModel.backURL)
                // CardTextView(caption: viewModel.caption, author: viewModel.author, time: viewModel.createdAt)
            }
            // StickerView(stickerURL: viewModel.stickerURL)
        }
    }
}
