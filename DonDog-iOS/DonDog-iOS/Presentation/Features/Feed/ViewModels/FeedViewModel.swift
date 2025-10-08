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
    @Published var postsList: [PostData] = []
    @Published var isLoading = false
    @Published var uploadStatus: String = ""
    
    private let photoSaveService = PhotoSaveService.shared
    
    init() {
        loadRoomPosts()
    }
    
    func didCaptureImages(frontImage: UIImage, backImage: UIImage) {
        selectedFrontImage = frontImage
        selectedBackImage = backImage
    }
    
    
    func didUploadToRoomPosts(postData: PostData) {
        uploadStatus = "Room posts 업로드 완료: \(postData.uid)"
        loadRoomPosts()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.uploadStatus = ""
        }
    }
    
    
    func loadRoomPosts() {
        photoSaveService.getCurrentUserRoomId { [weak self] result in
            switch result {
            case .success(let roomId):
                self?.photoSaveService.fetchRoomPosts(roomId: roomId) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let postsList):
                            self?.postsList = postsList
                            print("Room posts에서 \(postsList.count)개 게시물 로드 완료")
                        case .failure(let error):
                            print("Room posts 로드 실패: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                print("roomId 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }
}
