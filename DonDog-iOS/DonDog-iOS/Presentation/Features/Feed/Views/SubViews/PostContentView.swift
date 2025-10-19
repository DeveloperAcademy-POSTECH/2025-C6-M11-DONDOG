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
        ScrollView {
            VStack(alignment: .center) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 348, height: 464)
                    .cornerRadius(12)
                    .padding(.vertical, 8)
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
                
                Text(viewModel.caption ?? "")
                    .font(.title)
                    .padding(.top, 8)
                
                HStack(spacing: 4) {
                    Text(viewModel.authorName)
                        .font(.captionRegular13)
                        .foregroundColor(Color.ddGray600)
                    
                    Text(DataUtils.relativeTimeString(from: viewModel.createdAt))
                        .font(.captionRegular13)
                        .foregroundColor(Color.ddGray500)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            
            VStack(alignment: .leading) {
                ForEach(viewModel.comments) { comment in
                    CommentView(comment: comment, viewModel: viewModel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .contextMenu {
                            if viewModel.currentUser == comment.uid {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteComment(of: comment) }
                                } label: {
                                    Text("삭제")
                                    Image(systemName: "trash")
                                }
                            }
                        }
                }
            }
        }
    }
}
