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
    
    private let photoSaveService = PhotoSaveService.shared
    
    
    func uploadImagesToRoomPosts() {
        
        guard let frontImage = frontImage, let backImage = backImage else {
            print("❌ 전면 또는 후면 이미지가 없습니다")
            return
        }
        
        print("✅ 전면 이미지: \(frontImage.size), 후면 이미지: \(backImage.size)")
        isUploading = true
        
        photoSaveService.uploadImagesToRoomPosts(frontImage: frontImage, backImage: backImage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                switch result {
                case .success(let postData):
                    print("🎉 Room posts 업로드 성공: \(postData.uid)")
                    self?.delegate?.didUploadToRoomPosts(postData: postData)
                case .failure(let error):
                    print("💥 Room posts 업로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
}
