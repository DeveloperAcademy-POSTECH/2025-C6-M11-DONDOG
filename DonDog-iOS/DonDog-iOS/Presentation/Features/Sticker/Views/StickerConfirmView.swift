//
//  StickerDecoView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/2/25.
//

import Combine
import FirebaseAuth
import SwiftUI

struct StickerConfirmView: View {
    @StateObject var viewModel: StickerConfirmViewModel

    var body: some View {
        VStack {
            Text("만들어진 스티커를 확인해 주세요")
            
            Spacer()
            
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .padding(.bottom, 8)
            }
            
            Spacer()
            
            if viewModel.isUploading {
                ProgressView("업로드 중…")
            }
            if let error = viewModel.uploadError, !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button("스티커 저장하기") {
                viewModel.uploadSticker()
            }
            .disabled(viewModel.isUploading || viewModel.image == nil)
        }
        .navigationTitle("스티커 꾸미기")
        .navigationBarTitleDisplayMode(.inline)
    }
}
