//
//  PostFromArchiveView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct PostFromArchiveView: View {
    @EnvironmentObject var viewModel: PostDetailViewModel
    @Binding var currentIndex: Int
    @State private var shouldBeUpdated: Bool = false
    
    var body: some View {
        let posts = viewModel.posts
        
        TabView(selection: $currentIndex) {
            ForEach(Array(posts.enumerated()), id: \.offset) { idx, post in
                ScrollView {
                    CustomPageIndicator(
                        currentIndex: currentIndex + 1,
                        totalCount: posts.count
                    )
                    .padding(.vertical, 8)
                    
                    // TODO: update 방식 변경 필요 여부 확인
                    PostDetailContentView(postType: .archive, post: post, shouldBeUpdated: $shouldBeUpdated)
                        .tag(idx)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .bottom)
    }
}
