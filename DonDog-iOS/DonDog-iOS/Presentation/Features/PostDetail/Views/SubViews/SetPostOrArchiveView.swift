//
//  SetPostOrArchiveView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import SwiftUI

struct SetPostOrArchiveView: View {
    @StateObject var viewModel = SetPostOrArchiveViewModel()
    // TODO: ArchiveView에서 CurrentIndex 받아서 호출되는 것 맞는지 확인
    @State private var currentIndex: Int = 0
    
    let postType: PostType
    
    var body: some View {
        if postType == .post {
            PostDetailContentView(postType: .post)
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.offset) { idx, post in
                    PostDetailContentView(postType: .archive)
                        .tag(idx)
                }
            }
            .frame(maxWidth: .infinity)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}
