//
//  StickerDecoView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/2/25.
//

import SwiftUI

struct StickerDecoView: View {
    let image: UIImage?
    let onDone: (UIImage) -> Void

    var body: some View {
        VStack {
            // 상단: 사용자가 찍은 사진
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .padding(.bottom, 8)
            }
            
            // TODO: 꾸미기(스티커/툴바 등) 영역
            Text("스티커 꾸미기 도구 영역")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            Button("확인") {
                if let img = image { onDone(img) }
            }
        }
        .navigationTitle("스티커 꾸미기")
        .navigationBarTitleDisplayMode(.inline)
    }
}
