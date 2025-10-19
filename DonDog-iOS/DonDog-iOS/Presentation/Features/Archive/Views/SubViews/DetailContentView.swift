//
//  DetailContentView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/17/25.
//

import SwiftUI

struct DetailContentView: View {
    let post: ArchivePost
    let userNameByUid: [String: String]
    let onDelete: ((Comment) async -> Void)?
    
    var body: some View {
        ScrollView {
            // 폴라로이드 프레임
            ZStack {
                VStack {
                    // 사진
                    DetailPhotoView(post: post)
                    
                    // 캡션 + 작성자
                    DetailCaptionView(post: post, userNameByUid: userNameByUid)
                }
                .padding(.vertical, 8)
                
                // 스티커
            }
            .background(.ddWhite)
            .shadow(color: .ddBlack.opacity(0.05), radius: 2.5, x: 0, y: 3)
            
            // 댓글
            DetailCommentsView(
                comments: post.comments.map { ($0, userNameByUid[$0.uid] ?? "익명") },
                onDelete: onDelete
            )
        }
    }
}
