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
                        ZStack {
                            AsyncPhoto(url: viewModel.frontURL ?? URL(fileURLWithPath: ""))
                                .opacity(showingFront ? 1.0 : 0.0)
                            
                            AsyncPhoto(url: viewModel.backURL ?? URL(fileURLWithPath: ""))
                                .opacity(showingFront ? 0.0 : 1.0)
                        }
                        .cornerRadius(8)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingFront.toggle()
                            }
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
                
                Image(uiImage: viewModel.stickerImage)
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
    
    // 추후 분리
    private struct AsyncPhoto: View {
        let url: URL
        var body: some View {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .clipped()
                        .cornerRadius(10)
                        .transition(.opacity)
                case .failure:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ddGray600)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .overlay(Image(systemName: "photo").opacity(0.7))
                case .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ddGray600.opacity(0.2))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                @unknown default:
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                }
            }
        }
    }
}
