//
//  PostView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/4/25.
//

import SwiftUI

struct PostView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PostViewModel
    
    var body: some View {
        VStack {
            Text("Hello, World!")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        print("게시물이 삭제되었습니다.")
                    } label: {
                        Label("삭제하기", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
}

#Preview {
    PostView(viewModel: PostViewModel())
}
