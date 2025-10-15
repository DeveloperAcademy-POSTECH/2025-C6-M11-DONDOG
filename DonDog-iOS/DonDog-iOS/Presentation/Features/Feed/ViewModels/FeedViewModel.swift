//
//  FeedViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import UIKit
import FirebaseAuth
import FirebaseFirestore

final class FeedViewModel: ObservableObject, CameraViewModelDelegate, CaptionViewModelDelegate {
    @Published var selectedFrontImage: UIImage?
    @Published var selectedBackImage: UIImage?
    @Published var postsList: [PostData] = []
    @Published var images: [PostData] = []
    @Published var todayPost: PostData?
    @Published var todayFrontImage: UIImage?
    @Published var todayBackImage: UIImage?
    @Published var isLoading = false
    @Published var uploadStatus: String = ""
    @Published var currentRoomId: String = ""
    @Published var selectedPostId: String = ""
    @Published var sticker: UIImage?
    @Published var currentPost: PostData?
    @Published var currentNickname: String = ""
    @Published var currentPostIndex: Int = 0
    @Published var allTodayPosts: [PostData] = []
    @Published var allTodayImages: [(front: UIImage, back: UIImage, nickname: String)] = []
    
    
    private let photoSaveService = PhotoSaveService.shared
    private let db = Firestore.firestore()
    
    init() {
        loadTodayPosts()
        
        photoSaveService.getCurrentUserRoomId { [weak self] result in
            switch result {
            case .success(let roomId):
                DispatchQueue.main.async {
                    self?.currentRoomId = roomId
                    print("currentRoomId 초기화 완료: \(roomId)")
                }
            case .failure(let error):
                print("roomId 가져오기 실패: \(error.localizedDescription)")
            }
        }
        
        self.getStickerImage()
    }
    
    func getStickerImage() {
        if let uid = Auth.auth().currentUser?.uid {
            db.collection("Users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    print("recentSticker 불러오기 실패: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let stickerURLString = data["recentSticker"] as? String,
                      let url = URL(string: stickerURLString) else {
                    print("recentSticker 필드 없음 또는 형식 불일치")
                    return
                }

                PhotoSaveService.shared.downloadImage(from: url.absoluteString) { [weak self] result in
                    switch result {
                    case .success(let image):
                        DispatchQueue.main.async {
                            self?.sticker = image
                        }
                    case .failure(let error):
                        print("recentSticker 다운로드 실패: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func didCaptureImages(frontImage: UIImage, backImage: UIImage) {
        selectedFrontImage = frontImage
        selectedBackImage = backImage
    }
    
    
    func didUploadToRoomPosts(postData: PostData) {
        uploadStatus = "Room posts 업로드 완료: \(postData.uid)"
        loadTodayPosts()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.uploadStatus = ""
        }
    }
    
    // MARK: - CaptionViewModelDelegate
    func didUploadPost() {
        print("✅ 게시물 업로드 완료 - FeedView 새로고침")
        loadTodayPosts()
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

    func loadTodayPosts() {
        isLoading = true
        photoSaveService.getCurrentUserRoomId { [weak self] result in
            switch result {
            case .success(let roomId):
                self?.photoSaveService.fetchTodayRoomPosts(roomId: roomId) { result in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        switch result {
                        case .success(let todayPosts):
                            self?.images = todayPosts
                            self?.allTodayPosts = todayPosts
                            print("📅 오늘 찍은 \(todayPosts.count)개 게시물 로드 완료")
  
                            if let firstPost = todayPosts.first {
                                self?.selectedPostId = firstPost.postId
                                self?.currentPost = firstPost
                                self?.currentPostIndex = 0
                                self?.downloadAllTodayImages(posts: todayPosts)
                            } else {
                                print("📭 오늘 찍은 게시물이 없습니다")
                                self?.allTodayImages = []
                            }
                        case .failure(let error):
                            print("오늘 posts 로드 실패: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                print("roomId 가져오기 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func downloadTodayImages(from post: PostData) {
        print("🖼️ 이미지 다운로드 시작")
        
        let group = DispatchGroup()

        group.enter()
        photoSaveService.downloadImage(from: post.frontImageURL) { [weak self] result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    self?.todayFrontImage = image
                    print("✅ 전면 이미지 다운로드 성공")
                }
            case .failure(let error):
                print("❌ 전면 이미지 다운로드 실패: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        photoSaveService.downloadImage(from: post.backImageURL) { [weak self] result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    self?.todayBackImage = image
                    print("✅ 후면 이미지 다운로드 성공")
                }
            case .failure(let error):
                print("❌ 후면 이미지 다운로드 실패: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("🎉 오늘 이미지 다운로드 완료")
        }
    }
    
    private func downloadAllTodayImages(posts: [PostData]) {
        print("🖼️ 모든 게시물 이미지 다운로드 시작")
        allTodayImages = []
        
        let group = DispatchGroup()
        var downloadedImages: [(front: UIImage, back: UIImage, nickname: String)] = []
        
        for (index, post) in posts.enumerated() {
            group.enter()
            
            let imageGroup = DispatchGroup()
            var frontImage: UIImage?
            var backImage: UIImage?
            var nickname: String = "익명"
            
            // 전면 이미지 다운로드
            imageGroup.enter()
            photoSaveService.downloadImage(from: post.frontImageURL) { result in
                switch result {
                case .success(let image):
                    frontImage = image
                case .failure(let error):
                    print("❌ 전면 이미지 다운로드 실패: \(error.localizedDescription)")
                }
                imageGroup.leave()
            }
            
            // 후면 이미지 다운로드
            imageGroup.enter()
            photoSaveService.downloadImage(from: post.backImageURL) { result in
                switch result {
                case .success(let image):
                    backImage = image
                case .failure(let error):
                    print("❌ 후면 이미지 다운로드 실패: \(error.localizedDescription)")
                }
                imageGroup.leave()
            }
            
            // 사용자 이름 가져오기
            imageGroup.enter()
            getUserName(uid: post.uid) { name in
                nickname = name
                imageGroup.leave()
            }
            
            imageGroup.notify(queue: .main) {
                if let front = frontImage, let back = backImage {
                    downloadedImages.append((front: front, back: back, nickname: nickname))
                    print("✅ 게시물 \(index + 1) 이미지 다운로드 완료")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.allTodayImages = downloadedImages
            print("🎉 모든 게시물 이미지 다운로드 완료: \(downloadedImages.count)개")
            
            // 첫 번째 게시물을 현재 게시물로 설정
            if let firstPost = posts.first, let firstImage = downloadedImages.first {
                self.todayFrontImage = firstImage.front
                self.todayBackImage = firstImage.back
                self.currentNickname = firstImage.nickname
            }
        }
    }
    
    private func getUserName(uid: String, completion: @escaping (String) -> Void) {
        db.collection("Users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("사용자 이름 가져오기 실패: \(error.localizedDescription)")
                completion("익명")
                return
            }
            
            guard let data = snapshot?.data(),
                  let name = data["name"] as? String else {
                print("사용자 이름 필드 없음")
                completion("익명")
                return
            }
            
            completion(name)
        }
    }
    
    // 사용자 이름 가져오는 함수
    func getUserName(uid: String) {
        db.collection("Users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("사용자 이름 가져오기 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.currentNickname = "익명"
                }
                return
            }
            
            guard let data = snapshot?.data(),
                  let name = data["name"] as? String else {
                print("사용자 이름 필드 없음")
                DispatchQueue.main.async {
                    self?.currentNickname = "익명"
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.currentNickname = name
                print("✅ 사용자 이름 가져오기 성공: \(name)")
            }
        }
    }
    
    // 캐러셀에서 현재 선택된 게시물 업데이트
    func updateCurrentPost(at index: Int) {
        guard index >= 0 && index < allTodayPosts.count && index < allTodayImages.count else { return }
        
        currentPostIndex = index
        currentPost = allTodayPosts[index]
        selectedPostId = allTodayPosts[index].postId
        
        let imageData = allTodayImages[index]
        todayFrontImage = imageData.front
        todayBackImage = imageData.back
        currentNickname = imageData.nickname
        
    }
}
