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
        Group {
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.gray // 이미지가 없을 때 기본 배경
                    }
                }
            .onAppear {
                viewModel.makeSticker()
            }
    }
}

#Preview {
    PostView()
}
