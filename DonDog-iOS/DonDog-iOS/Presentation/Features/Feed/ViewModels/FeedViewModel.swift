//
//  FeedViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import UIKit

final class FeedViewModel: ObservableObject, CameraViewModelDelegate {
    @Published var selectedFrontImage: UIImage?
    @Published var selectedBackImage: UIImage?
    
    // CameraViewModelDelegate 구현
    func didCaptureImages(frontImage: UIImage, backImage: UIImage) {
        selectedFrontImage = frontImage
        selectedBackImage = backImage
    }
}
