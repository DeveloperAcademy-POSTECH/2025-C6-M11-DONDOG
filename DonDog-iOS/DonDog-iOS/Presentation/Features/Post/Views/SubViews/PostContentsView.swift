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
    @ObservedObject var viewModel: StickerViewModel
    @Binding var showDetail: Bool
    @Binding var isFrontOrBack: Int
    
    var body: some View {
        VStack(alignment: .leading) {
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
            .frame(height: 470)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .padding(.bottom, 10)
            
            Text(post.caption)
                .font(.polaroidCaptionRegular16)
                .foregroundStyle(.ddGray1000)
                .padding(.bottom, 2)
                .padding(.leading, 4)
            
            Text(DateUtils.relativeTimeString(from: post.createdAt.dateValue()))
                .font(.captionRegular13)
                .foregroundStyle(.ddGray500)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 20)
        .gesture(isEditing ? nil : DragGesture())
    }
}
