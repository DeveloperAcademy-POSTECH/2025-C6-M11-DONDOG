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
    @Published var imageDataList: [ImageData] = []
    @Published var isLoading = false
    @Published var uploadStatus: String = ""
    
    private let photoSaveService = PhotoSaveService.shared
    
    init() {
        loadImagesFromFirebase()
    }
    
    func didCaptureImages(frontImage: UIImage, backImage: UIImage) {
        selectedFrontImage = frontImage
        selectedBackImage = backImage
    }
    
    func didUploadToFirebase(imageData: ImageData) {
        uploadStatus = "업로드 완료: \(imageData.id)"
        loadImagesFromFirebase()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.uploadStatus = ""
        }
    }
    
    func loadImagesFromFirebase() {
        isLoading = true
        
        photoSaveService.fetchImageData { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let imageDataList):
                    self?.imageDataList = imageDataList
                    print("Firebase에서 \(imageDataList.count)개 이미지 로드 완료")
                case .failure(let error):
                    print("Firebase 이미지 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
}
