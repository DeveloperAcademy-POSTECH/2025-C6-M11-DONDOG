//
//  CaptionViewModel.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/9/25.
//

import SwiftUI
import Combine

protocol CaptionViewModelDelegate: AnyObject {
    func didUploadPost()
}

final class CaptionViewModel: ObservableObject {
    @Published var caption: String = ""
    @Published var isUploading: Bool = false
    
    weak var delegate: CaptionViewModelDelegate?
    
    var frontImage: UIImage?
    var backImage: UIImage?
    
    private let photoSaveService = PhotoSaveService.shared
    
    init(frontImage: UIImage?, backImage: UIImage?) {
        self.frontImage = frontImage
        self.backImage = backImage
    }
    
    func uploadPost(onSuccess: @escaping () -> Void) {
        guard let frontImage = frontImage, let backImage = backImage else {
            print("❌ 전면 또는 후면 이미지가 없습니다")
            return
        }
        
        print("📤 업로드 시작 - 캡션: \(caption)")
        isUploading = true
        
        photoSaveService.uploadImagesToRoomPosts(
            frontImage: frontImage,
            backImage: backImage,
            caption: caption
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                switch result {
                case .success(let postData):
                    print("✅ 업로드 성공: \(postData.uid)")
                    print("📝 캡션: \(postData.caption)")
                    self?.delegate?.didUploadPost()
                    onSuccess()
                case .failure(let error):
                    print("❌ 업로드 실패: \(error.localizedDescription)")
                }
                
                
            }
        }
    }
}

