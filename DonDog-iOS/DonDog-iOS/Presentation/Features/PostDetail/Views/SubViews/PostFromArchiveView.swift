//
//  PostFromArchiveView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import SwiftUI

struct PostFromArchiveView: View {
    @StateObject var viewModel = PostFromArchiveViewModel()
    
    var body: some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { idx, post in
                ScrollView {
                    CustomPageIndicator(
                        currentIndex: viewModel.currentIndex + 1,
                        totalCount: viewModel.posts.count
                    )
                    .padding(.vertical, 8)
                    
                    PostDetailContentView(postType: .archive, post: post)
                        .tag(idx)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .bottom)
    }
}
