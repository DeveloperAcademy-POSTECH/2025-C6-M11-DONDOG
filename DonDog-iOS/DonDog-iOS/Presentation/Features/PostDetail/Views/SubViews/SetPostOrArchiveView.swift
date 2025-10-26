//
//  SetPostOrArchiveView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import SwiftUI

struct SetPostOrArchiveView: View {
    @StateObject var viewModel = SetPostOrArchiveViewModel()
    
    let postType: PostType
    
    var body: some View {
        if postType == .post {
//            PostDetailContentView(postType: .post)
        } else {
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
}
