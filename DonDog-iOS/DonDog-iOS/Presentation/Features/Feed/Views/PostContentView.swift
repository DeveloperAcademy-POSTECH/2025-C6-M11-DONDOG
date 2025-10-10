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
                Image(uiImage: viewModel.frontImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 465)
                    .padding(.top, 23)
                Text("test")
            }
        }
    }
}
