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
    
    @State private var isFrontOrBack: Int = 0
    
    var body: some View {
        VStack(alignment: .center) {
            Text(DateUtils.relativeTimeString(from: post.createdAt.dateValue()))
                .font(.captionRegular13)
                .foregroundStyle(.ddGray500)
                .padding(.bottom, 23)
            
            TabView(selection: $isFrontOrBack) {
                ImageView(urlString: post.frontImageURL)
                    .tag(0)

                ImageView(urlString: post.backImageURL)
                    .tag(1)
            }
            .frame(height: 524)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .padding(.bottom, 27)
            
            Text(post.caption)
                .font(.polaroidCaptionRegular20)
                .foregroundStyle(.ddGray1000)
            
            Spacer()
            
            CustomButton(title: "스티커 붙이기", isEnable: true, action: { print("스티커 편집뷰로 이동") })
        }
        .padding(.horizontal, 20)
    }
}

private struct ImageView: View {
    let urlString: String
    @State private var loadFailed: Bool = false

    private var url: URL? {
        URL(string: urlString)
    }

    var body: some View {
        ZStack {
            KFImage(url)
                .placeholder {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.ddGray500)
                }
                .onFailure { _ in
                    loadFailed = true
                }
                .cancelOnDisappear(true)
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
                .clipped()
                .overlay(alignment: .center) {
                    if loadFailed {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.ddGray500)
                            .overlay(Image(systemName: "photo"))
                    }
                }
            
            StickerView()
        }
    }
}
