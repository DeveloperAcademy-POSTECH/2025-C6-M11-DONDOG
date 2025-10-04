//
//  PostViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/4/25.
//

import Combine
import SwiftUI

final class PostViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    
    func getImage() {
        // 나중에 Firebase URL 이미지로 바꿀 예정
        image = UIImage(named: "StickerImage")
    }
    
    func makeSticker() {
        getImage()
    }
}
