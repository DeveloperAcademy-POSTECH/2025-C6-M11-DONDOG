//
//  StickerView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import SwiftUI

struct StickerView: View {
    @StateObject var viewModel = StickerViewModel()
    
    let stickerPostId: String
    let stickerType: String
    
    var body: some View {
        if let uiImage = viewModel.borderedStickers[stickerPostId] {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        }
    }
}
