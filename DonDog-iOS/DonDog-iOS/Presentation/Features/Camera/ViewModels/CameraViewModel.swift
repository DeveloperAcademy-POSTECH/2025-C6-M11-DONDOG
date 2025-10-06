//
//  CameraViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import UIKit
import SwiftUI

protocol CameraViewModelDelegate: AnyObject {
    func didCaptureImages(frontImage: UIImage, backImage: UIImage)
    func didUploadToFirebase(imageData: ImageData)
}

final class CameraViewModel: ObservableObject {
    weak var delegate: CameraViewModelDelegate?
    var frontImage: UIImage?
    var backImage: UIImage?
    @Published var isUploading = false
    
    private let photoSaveService = PhotoSaveService.shared
    
    func uploadImagesToFirebase() {
        print("📷 uploadImagesToFirebase 호출됨")
        
        guard let frontImage = frontImage, let backImage = backImage else {
            print("❌ 이미지가 없습니다")
            return
        }
        
        print("✅ 이미지 확인됨 - 전면: \(frontImage.size), 후면: \(backImage.size)")
        isUploading = true
        
        photoSaveService.uploadImages(frontImage: frontImage, backImage: backImage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                switch result {
                case .success(let imageData):
                    print("🎉 Firebase 업로드 성공: \(imageData.id)")
                    self?.delegate?.didUploadToFirebase(imageData: imageData)
                case .failure(let error):
                    print("💥 Firebase 업로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
}
