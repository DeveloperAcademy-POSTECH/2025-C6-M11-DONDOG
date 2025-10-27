//
//  CardView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI
import FirebaseCore

struct CardView: View {
    let post: PostData
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    CardPhotoView(frontImageURL: post.frontImageURL, backImageURL: post.backImageURL)
                    
                    CardTextView(caption: post.caption, authorId: post.authorId, createdAt: post.createdAt.dateValue())
                }
                
                StickerView(stickerPostId: post.stickerPostId, stickerType: post.stickerType ?? "")
            }
        }
    }
}
