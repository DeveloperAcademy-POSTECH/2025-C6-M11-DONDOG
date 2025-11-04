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
                        goToDeco = true
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
                if let image = image {
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
