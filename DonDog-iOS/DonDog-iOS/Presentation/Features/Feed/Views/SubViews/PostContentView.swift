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
    @State private var authorName: String = "익명"
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05),
                            radius: 5,
                            x: 0,
                            y: 3)
                HStack {
                    Spacer()
                    
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
                            .font(.polaroidCaptionRegular20)
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
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                // TODO: FeedView에서 프레임까지 완성된 StickerImage UIImage로 받아와서 띄우기
                Image(uiImage: viewModel.borderedSticker ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 120)
            }
            .padding(.bottom, 5)
            
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
