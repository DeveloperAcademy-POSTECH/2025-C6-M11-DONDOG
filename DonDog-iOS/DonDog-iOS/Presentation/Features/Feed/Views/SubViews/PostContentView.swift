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
                        
                        VStack {
                            VStack {
                                if let cap = viewModel.caption, !cap.isEmpty {
                                    Text(cap)
                                        .font(.polaroidCaptionRegular20)
                                        .foregroundStyle(.ddGray1000)
                                } else {
                                    Text(" ")
                                        .hidden()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 27) // 캡션이 없어도 높이 고정되게
                            
                            HStack(spacing: 4) {
                                if !viewModel.authorName.isEmpty {
                                    Text(viewModel.authorName)
                                        .foregroundStyle(.ddGray600)
                                } else {
                                    Text("익명")
                                        .foregroundStyle(.ddGray600)
                                }
                                
                                Text(DataUtils.relativeTimeString(from: viewModel.createdAt))
                                    .foregroundStyle(.ddGray500)
                            }
                            .font(.captionRegular13)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
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
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.commentToDelete = comment
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
