//
//  PostContentsView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI
import FirebaseCore

struct PostContentsView: View {
    let post: PostData
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.ddWhite
                .overlay(
                    LinearGradient(
                        colors: [.ddBlack.opacity(0.05), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 3),
                    alignment: .bottom
                )
            
            VStack(spacing: 0) {
                PhotoView(frontImageURL: post.frontImageURL, backImageURL: post.backImageURL)
                
                TextView(caption: post.caption, authorId: post.authorId, createdAt: post.createdAt.dateValue())
            }
            
            StickerView(postId: post.postId, stickerType: post.stickerType)
        }
    }
}
