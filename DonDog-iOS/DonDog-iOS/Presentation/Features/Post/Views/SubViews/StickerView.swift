//
//  StickerView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import SwiftUI

struct StickerView: View {
    let postId: String
    let stickerType: String?
    @State private var sticker: UIImage = UIImage()
    
    var body: some View {
        Image(uiImage: sticker)
            .resizable()
            .scaledToFit()
            .frame(width: 140)
            .task {
                guard let stickerType = stickerType, !stickerType.isEmpty else {
                    sticker = UIImage()
                    return
                }
                
                let stickers = await StickerService().getStickerCollection(of: postId)
                sticker = stickers[stickerType] ?? UIImage()
            }
    }
}
