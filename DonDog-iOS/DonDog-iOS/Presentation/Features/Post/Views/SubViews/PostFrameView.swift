//
//  PostFrameView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/30/25.
//

import FirebaseCore
import SwiftUI

struct PostFrameView: View {
    @Binding var currentIndex: Int
    @StateObject var viewModel: PostViewModel
    let postType: PostType
    
    var body: some View {
        if postType == .post {
            if let post = viewModel.posts.first {
                PostContentsView(post: post)
            } else {
                EmptyView()
            }
        } else {
            let posts = viewModel.posts
            
            TabView(selection: $currentIndex) {
                ForEach(Array(posts.enumerated()), id: \.offset) { idx, post in
                    ScrollView {
                        CustomPageIndicator(
                            currentIndex: currentIndex + 1,
                            totalCount: posts.count
                        )
                        .padding(.vertical, 8)
                        
                        PostContentsView(post: post)
                            .tag(idx)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}
