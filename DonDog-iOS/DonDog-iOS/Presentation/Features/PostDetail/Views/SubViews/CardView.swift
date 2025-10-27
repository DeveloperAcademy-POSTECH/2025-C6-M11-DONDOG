//
//  CardView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct CardView: View {
    let post: PostData
    
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
