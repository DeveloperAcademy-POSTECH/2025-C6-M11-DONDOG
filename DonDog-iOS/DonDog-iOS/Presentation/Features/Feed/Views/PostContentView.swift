//
//  PostContentView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/9/25.
//

import SwiftUI

struct PostContentView: View {
    @StateObject var viewModel: PostViewModel
    
    var body: some View {
        ScrollView() {
            VStack {
                ZStack(alignment: .bottom) {
                    Image(uiImage: viewModel.frontImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 465)
                        .padding(.top, 23)
                    HStack(spacing: 5) {
                        let caption = viewModel.caption ?? ""
                        ForEach(Array(caption.enumerated()), id: \.offset) { idx, char in
                            Text(String(char))
                                .font(.system(size: 20, weight: .regular))
                                .padding(.vertical, 5)
                                .padding(.horizontal, 8)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }

                    }
                    .padding(.bottom, 38)
                }
                Text("test")
            }
        }
    }
}
