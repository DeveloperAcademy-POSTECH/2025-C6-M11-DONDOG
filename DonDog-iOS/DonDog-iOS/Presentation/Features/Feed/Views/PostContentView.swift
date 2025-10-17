//
//  PostContentView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/9/25.
//

import SwiftUI
import FirebaseCore

struct PostContentView: View {
    @StateObject var viewModel: PostViewModel
    @State private var image: UIImage = UIImage()
    @State private var showingFront = true
    @State private var authorName:String = "익명"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 23) {
            ZStack(alignment: .bottom) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 465)
                    .onTapGesture {
                        showingFront.toggle()
                        image = showingFront ? (viewModel.frontImage) : (viewModel.backImage)
                    }
                    .onReceive(viewModel.$frontImage) { newFront in
                        if showingFront { image = newFront }
                    }
                    .onReceive(viewModel.$backImage) { newBack in
                        if !showingFront { image = newBack }
                    }
                
                HStack(spacing: 5) {
                    let caption = viewModel.caption ?? ""
                    ForEach(Array(caption.enumerated()), id: \.offset) { idx, char in
                        Text(String(char))
                            .font(.system(size: 20, weight: .regular))
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(Color.gray)
                            .cornerRadius(4)
                    }
                }
                .padding(.bottom, 38)
            }
            
            ForEach(viewModel.comments) { comment in
                CommentView(comment: comment, viewModel: viewModel)
            }
        }
    }
}
