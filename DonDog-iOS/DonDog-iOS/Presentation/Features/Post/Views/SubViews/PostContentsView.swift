//
//  PostContentsView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import FirebaseCore
import Kingfisher
import SwiftUI

struct PostContentsView: View {
    let post: PostData
    @Binding var isEditing: Bool
    @StateObject var viewModel: StickerViewModel
    @Binding var showDetail: Bool
    @Binding var isFrontOrBack: Int
    
    var body: some View {
        VStack {
            TabView(selection: $isFrontOrBack) {
                VStack(spacing: 0) {
                    ImageView(urlString: post.frontImageURL, isEditing: $isEditing, viewModel: viewModel)
                        .onTapGesture {
                                showDetail = true
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    Rectangle()
                        .frame(height: 40)
                        .foregroundStyle(.ppWhite)
                }
                .tag(0)
                .padding(.horizontal, 20)
                
                VStack(spacing: 0) {
                    ImageView(urlString: post.backImageURL, isEditing: $isEditing, viewModel: viewModel)
                        .onTapGesture {
                                showDetail = true
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    Rectangle()
                        .frame(height: 40)
                        .foregroundStyle(.ppWhite)
                }
                .tag(1)
                .padding(.horizontal, 20)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(maxHeight: 510)
            
            VStack(spacing: 4) {
                Text(post.caption)
                    .font(.bodyRegular16)
                    .foregroundStyle(.ppBlack)
                
                Text(DateUtils.relativeTimeString(from: post.createdAt.dateValue()))
                    .font(.captionRegular13)
                    .foregroundStyle(.ppGray500)
            }
            .padding(.bottom, 50)
            
            Spacer()
        }
        .padding(.top, 44)
        .onChange(of: isFrontOrBack) { _, newValue in
            Task {
                viewModel.postImageType = (newValue == 0) ? .front : .back
                await viewModel.fetchStickers()
            }
        }
    }
}
