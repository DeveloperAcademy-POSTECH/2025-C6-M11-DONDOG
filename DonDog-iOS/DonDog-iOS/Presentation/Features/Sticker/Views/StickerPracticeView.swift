//
//  StickerPracticeView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/5/25.
//

import SwiftUI
import UIKit

struct StickerPracticeView: View {
    @State private var resultImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            Button {
                print("클릭")
                guard let base = UIImage(named: "Practice") else {
                    print("Practice 이미지 에셋을 UIImage로 로드할 수 없습니다.")
                    return
                }
                Task {
                    let image = await StickerService().makeSticker(from: base, title: "그리워")
                    await MainActor.run {
                        self.resultImage = image
                    }
                }
            } label: {
                Text("스티커 만들기")
            }

            if let resultImage {
                Image(uiImage: resultImage)
                    .resizable()
                    .scaledToFit()
                    .border(Color.red, width: 1)
                    .frame(maxHeight: 300)
            }
        }
        .padding()
    }
}

#Preview {
    StickerPracticeView()
}
