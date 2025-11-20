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
    @Binding var isFrontOrBack: Int
    @Binding var isZooming: Bool
    @Binding var isShowDetail: Bool
    
    var body: some View {
        VStack {
            TabView(selection: $isFrontOrBack) {
                VStack(spacing: 0) {
                    GeometryReader {
                        let size = $0.size
                        ImageView(urlString: post.frontImageURL, isEditing: $isEditing, viewModel: viewModel, isZooming: $isZooming, isShowDetail: $isShowDetail)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: isShowDetail ? 0 : 15))
                            .pinchZoom(isZooming: $isZooming)
                    }
                    .frame(height: isShowDetail ? 524 : 470)
                    
                    Rectangle()
                        .frame(height: isShowDetail ? 0 : 40)
                        .foregroundStyle(.ppWhite)
                }
                .tag(0)
                .padding(.horizontal, isShowDetail ? 0 : 20)
                
                VStack(spacing: 0) {
                    GeometryReader {
                        let size = $0.size
                        ImageView(urlString: post.backImageURL, isEditing: $isEditing, viewModel: viewModel, isZooming: $isZooming, isShowDetail: $isShowDetail)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: isShowDetail ? 0 : 15))
                            .pinchZoom(isZooming: $isZooming)
                    }
                    .frame(height: isShowDetail ? 524 : 470)
                    
                    Rectangle()
                        .frame(height: isShowDetail ? 0 : 40)
                        .foregroundStyle(.ppWhite)
                }
                .tag(1)
                .padding(.horizontal, isShowDetail ? 0 : 20)
            }
            .tabViewStyle(.page(indexDisplayMode: isShowDetail ? .never : .always))
            .frame(maxHeight: isShowDetail ? 524 : 510)
            
            VStack(spacing: 4) {
                Text(isShowDetail ? "" : post.caption)
                    .font(.bodyRegular16)
                    .foregroundStyle(.ppBlack)
                
                Text(isShowDetail ? "" : DateUtils.relativeTimeString(from: post.createdAt.dateValue()))
                    .font(.captionRegular13)
                    .foregroundStyle(.ppGray500)
            }
            .padding(.bottom, isShowDetail ? 0 : 50)
            
            if isShowDetail {
                HStack(spacing: 7) {
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundStyle(isFrontOrBack == 0 ? .ppWhite : .ppWhite.opacity(0.3))
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundStyle(isFrontOrBack == 1 ? .ppWhite : .ppWhite.opacity(0.3))
                }
            }
            
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
