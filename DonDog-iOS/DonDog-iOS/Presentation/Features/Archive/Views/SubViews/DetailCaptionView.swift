//
//  DetailCaptionView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/17/25.
//

import SwiftUI

struct DetailCaptionView: View {
    let post: ArchivePost
    
    var body: some View {
        VStack {
            VStack {
                if let cap = post.caption, !cap.isEmpty {
                    Text(cap)
                        .font(.polaroidCaptionRegular20)
                        .foregroundStyle(.ddGray1000)
                } else {
                    Text(" ")
                        .hidden()
                }
            }
            .frame(height: 27) // 캡션이 없어도 높이 고정되게
            
            HStack(spacing: 4) {
                if let author = post.authorName, !author.isEmpty {
                    Text(author)
                        .foregroundStyle(.ddGray600)
                }
                Text(DataUtils.relativeTimeString(from: post.createdAt))
                    .foregroundStyle(.ddGray500)
            }
            .font(.captionRegular13)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
    }
}
