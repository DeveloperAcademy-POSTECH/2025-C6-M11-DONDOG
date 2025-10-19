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
    @Published var selectedPostId: String = "" {
        didSet {
            checkIsNotMyPost()
        }
    }
    @Published var stickerImage: UIImage?
    @Published var sticker: UIImage?
    @Published var currentPost: PostData?
    @Published var currentNickname: String = ""
    @Published var currentPostIndex: Int = 0
    @Published var displayablePosts: [DisplayablePost] = []
    @Published var frame: UIImage?
    @Published var emotion: String = "null"
    @Published var isNotMyPost = false
    @Published var selectedStickerEmotion: String? = nil
    
    private let photoSaveService = PhotoSaveService.shared
    private let db = Firestore.firestore()
    private let imageUtils = ImageUtils()
    
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
        
        self.getStickerData()
    }
    
    func checkIsNotMyPost() {
        guard !currentRoomId.isEmpty, !selectedPostId.isEmpty else {
            print("currentRoomId 또는 selectedPostId가 비어 있음")
            return
        }
        
        let postRef = db.collection("Rooms")
            .document(currentRoomId)
            .collection("posts")
            .document(selectedPostId)

        postRef.getDocument { snapshot, error in
            if let error = error {
                print("문서 조회 실패: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let uid = data["uid"] as? String,
                  let currentUid = Auth.auth().currentUser?.uid else {
                return
            }

            self.isNotMyPost = uid != currentUid
        }
    }
    
    func getStickerData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("Users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("recentPostId 불러오기 실패: \(error.localizedDescription)")
                return
            }
            
            guard
                let self = self,
                let data = snapshot?.data(),
                let recentPostId = data["recentPostId"] as? String,
                !recentPostId.isEmpty
            else {
                print("recentPostId 없음")
                return
            }
            
            self.photoSaveService.getCurrentUserRoomId { result in
                switch result {
                case .success(let roomId):
                    let postRef = self.db.collection("Rooms").document(roomId)
                        .collection("posts").document(recentPostId)
                    
                    postRef.getDocument { snapshot, error in
                        if let error = error {
                            print("recentPostId 문서 조회 실패: \(error.localizedDescription)")
                            return
                        }
                        
                        guard
                            let postData = snapshot?.data(),
                            let imageUrlString = postData["frontImageURL"] as? String
                        else {
                            print("frontImageURL 없음")
                            return
                        }
                        
                        PhotoSaveService.shared.downloadImage(from: imageUrlString) { [weak self] result in
                            switch result {
                            case .success(let image):
                                DispatchQueue.main.async {
                                    self?.stickerImage = image
                                    print("recentSticker 이미지 로드 성공")
                                    
                                    self?.makeStickerAndMask(with: image)
                                    
                                    self?.emotion = postData["stickerType"] as? String ?? "null"
                                }
                            case .failure(let error):
                                print("이미지 다운로드 실패: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("roomId 불러오기 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func makeStickerAndMask(with stickerImage: UIImage) {
        frame = imageUtils.makeMask(from: stickerImage)
        sticker = imageUtils.makeSticker(with: stickerImage)
    }
    
    func updateStickerData() {
        guard !currentRoomId.isEmpty, !selectedPostId.isEmpty else {
            print("currentRoomId 또는 selectedPostId가 비어 있어 업데이트 불가")
            return
        }

        let postRef = db.collection("Rooms")
            .document(currentRoomId)
            .collection("posts")
            .document(selectedPostId)

        let batch = db.batch()
        batch.updateData([
            "stickerPostId": selectedPostId,
            "stickerType": emotion,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: postRef)

        batch.commit { error in
            if let error = error {
                print("업데이트 실패: \(error.localizedDescription)")
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
                            print("📅 오늘 찍은 \(todayPosts.count)개 게시물 로드 완료")
  
                            if let firstPost = todayPosts.first {
                                self?.selectedPostId = firstPost.postId
                                self?.currentPost = firstPost
                                self?.currentPostIndex = 0
                                self?.downloadAllTodayImages(posts: todayPosts)
                            } else {
                                print("📭 오늘 찍은 게시물이 없습니다")
                                self?.displayablePosts = []
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
        displayablePosts = []
        
        // 현재 사용자 UID 가져오기
        let currentUserUid = Auth.auth().currentUser?.uid ?? ""
        
        let group = DispatchGroup()
        var tempDisplayablePosts: [Int: DisplayablePost] = [:]  // 인덱스와 함께 저장
        
        for (index, post) in posts.enumerated() {
            group.enter()
            
            // 내 게시물인지 확인
            let isMyPost = (post.uid == currentUserUid)
            var displayablePost = DisplayablePost(post: post, isMyPost: isMyPost)
            let imageGroup = DispatchGroup()
            
            // 전면 이미지 다운로드
            imageGroup.enter()
            photoSaveService.downloadImage(from: post.frontImageURL) { result in
                switch result {
                case .success(let image):
                    displayablePost.frontImage = image
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
                    displayablePost.backImage = image
                case .failure(let error):
                    print("❌ 후면 이미지 다운로드 실패: \(error.localizedDescription)")
                }
                imageGroup.leave()
            }
            
            // 사용자 이름 가져오기
            imageGroup.enter()
            getUserName(uid: post.uid) { name in
                displayablePost.nickname = name
                imageGroup.leave()
            }
            
            imageGroup.notify(queue: .main) {
                if displayablePost.isReady {
                    tempDisplayablePosts[index] = displayablePost  // 인덱스로 저장
                    print("✅ 게시물 \(index + 1) 이미지 다운로드 완료")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // 인덱스 순서대로 정렬하여 배열로 변환
            let sortedPosts = tempDisplayablePosts.sorted(by: { $0.key < $1.key }).map { $0.value }
            self.displayablePosts = sortedPosts
            print("🎉 모든 게시물 이미지 다운로드 완료: \(sortedPosts.count)개 (순서 유지)")
            
            // 첫 번째 게시물을 현재 게시물로 설정
            if let firstDisplayablePost = sortedPosts.first {
                self.todayFrontImage = firstDisplayablePost.frontImage
                self.todayBackImage = firstDisplayablePost.backImage
                self.currentNickname = firstDisplayablePost.nickname
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
        guard index >= 0 && index < displayablePosts.count else { return }
        
        let displayablePost = displayablePosts[index]
        
        currentPostIndex = index
        currentPost = displayablePost.post
        selectedPostId = displayablePost.postId
        todayFrontImage = displayablePost.frontImage
        todayBackImage = displayablePost.backImage
        currentNickname = displayablePost.nickname
    }
}
