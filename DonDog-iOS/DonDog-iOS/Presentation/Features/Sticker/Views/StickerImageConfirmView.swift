//
//  StickerImageConfirmView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/2/25.
//

import SwiftUI

struct StickerImageConfirmView: View {
    let image: UIImage?
    let onConfirm: (_ accepted: Bool, _ result: UIImage?) -> Void
    @State private var goToDeco: Bool = false
    
    @State private var isProcessing: Bool = false
    @State private var processedImage: UIImage?
    
    private let stickerService = StickerService()
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("스티커 미리보기")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }
                Spacer()
                
                if isProcessing {
                    ProgressView("스티커 생성 중…")
                }
                
                HStack {
                    Button {
                        onConfirm(false, nil)
                    } label: {
                        Text("재촬영")
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    Button {
                        guard let base = image, !isProcessing else { return }
                        isProcessing = true
                        Task {
                            let tags = StickerEmotionTagManager.shared.emotionTags
                            let title = tags[1]
                            let result = await StickerService().makeSticker(from: base, title: title)
                            
                            self.processedImage = result
                            self.isProcessing = false
                            self.goToDeco = (result != nil)
                        }
                    } label: {
                        Text("스티커 만들기")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 12)
            .navigationDestination(isPresented: $goToDeco) {
                if let image = processedImage {
                    StickerConfirmView(
                        viewModel: StickerConfirmViewModel(
                            image: image
                        ) { resultImage in
                            onConfirm(true, resultImage)
                        }
                    )
                }
            }
        }
        
        
    }
}
