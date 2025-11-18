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
            if !isEditing {
                TabView(selection: $isFrontOrBack) {
                    ImageView(urlString: post.frontImageURL, isEditing: $isEditing, viewModel: viewModel)
                        .tag(0)
                        .onTapGesture {
                            if !isEditing {
                                showDetail = true
                            }
                        }
                    
                    ImageView(urlString: post.backImageURL, isEditing: $isEditing, viewModel: viewModel)
                        .tag(1)
                        .onTapGesture {
                            if !isEditing {
                                showDetail = true
                            }
                        }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 470)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 10)
            } else {
                ImageView(urlString: isFrontOrBack == 0 ? post.frontImageURL : post.backImageURL, isEditing: $isEditing, viewModel: viewModel)
                    .frame(height: 470)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.bottom, 10)
            }
            
            Text(post.caption)
                .font(.polaroidCaptionRegular16)
                .foregroundStyle(.ppBlack)
                .padding(.top, 8)
                .padding(.bottom, 2)
            
            Text(DateUtils.relativeTimeString(from: post.createdAt.dateValue()))
                .font(.captionRegular13)
                .foregroundStyle(.ppGray500)
            
            Spacer()
        }
        .padding(.top, 64)
        .padding(.horizontal, 20)
        .gesture(isEditing ? nil : DragGesture())
        .onChange(of: isFrontOrBack) { _, newValue in
            Task {
                viewModel.postImageType = (newValue == 0) ? .front : .back
                await viewModel.fetchStickers()
            }
        }
    }
}
