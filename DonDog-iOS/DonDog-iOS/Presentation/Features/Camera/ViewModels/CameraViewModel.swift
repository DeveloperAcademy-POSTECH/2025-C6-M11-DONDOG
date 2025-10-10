//
//  CameraViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import SwiftUI
import UIKit


protocol CameraViewModelDelegate: AnyObject {
    func didCaptureImages(frontImage: UIImage, backImage: UIImage)
    func didUploadToRoomPosts(postData: PostData)
}

final class CameraViewModel: ObservableObject {
    weak var delegate: CameraViewModelDelegate?
    var frontImage: UIImage?
    var backImage: UIImage?
    @Published var isUploading = false
    @Published var showCaptionView = false
}
