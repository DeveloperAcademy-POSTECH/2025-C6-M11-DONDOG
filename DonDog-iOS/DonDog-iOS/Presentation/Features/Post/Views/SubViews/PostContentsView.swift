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
        VStack {
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
            .frame(height: 470)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .padding(.bottom, 27)
            
            Text(post.caption)
                .font(.polaroidCaptionRegular20)
                .foregroundStyle(.ddGray1000)
        }
        .padding(.horizontal, 20)
    }
}
