//
//  PostView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/4/25.
//

import SwiftUI

struct PostView: View {
    @StateObject var viewModel = PostViewModel()
    
    var body: some View {
        // 이미지 로드 실패 시 어떻게 할 건 지 논의 후 예외 처리 예정
        Image(uiImage: viewModel.image ?? UIImage())
            .resizable()
            .scaledToFit()
            .onAppear {
                viewModel.makeSticker()
            }
    }
}

#Preview {
    PostView()
}
