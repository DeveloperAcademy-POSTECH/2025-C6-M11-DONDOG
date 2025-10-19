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
    @Published var borderedStickers: [String: UIImage] = [:]  // 감정별 테두리 적용된 스티커
    
    private let photoSaveService = PhotoSaveService.shared
    private let db = Firestore.firestore()
    private let imageUtils = ImageUtils()
    
    init() {
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
        loadTodayPosts()
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
                                    
//                                    if self?.currentPost?.stickerPostId != "" {
//                                        // 1. currentPost의 stickerPostId를 이용해서 해당 post에 대응된 스티커 이미지 url 가져오기
//                                        // 2. 1번에서 가져온 url로 UIImage 가져오기
//                                        self?.makeStickerAndMask(with: ) // 3. 여기 with: 뒤에 2번에서 가져온 UIImage 넣기
//                                    } else {
//                                        self?.makeStickerAndMask(with: image)
//                                    }
                                    
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
        // 🚀 모든 이미지 처리를 백그라운드에서 수행
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let maskImage = self.imageUtils.makeMask(from: stickerImage)
            let stickerOnly = self.imageUtils.makeSticker(with: stickerImage)
            
            guard let sticker = stickerOnly else {
                print("❌ 스티커 생성 실패")
                return
            }
            
            // 5가지 감정 테두리 생성 (병렬 처리 가능)
            let emotions: [(String, UIColor)] = [
                ("사랑해", .ddFeelingPink),
                ("멋지다", .ddFeelingYellow),
                ("뭐야?", .ddFeelingGreen),
                ("화나", .ddFeelingOrange),
                ("슬퍼", .ddFeelingBlue)
            ]
            
            var bordered: [String: UIImage] = [:]
            for (emotion, color) in emotions {
                if let borderedImage = sticker.addBorder(thickness: 4, color: color) {
                    bordered[emotion] = borderedImage
                }
            }
            
            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                self.frame = maskImage
                self.sticker = sticker
                self.borderedStickers = bordered
                print("✅ 스티커 및 5가지 감정 테두리 생성 완료")
            }
        }
    }
    
    
    func updateStickerData() {
        guard !currentRoomId.isEmpty, !selectedPostId.isEmpty else {
            print("currentRoomId 또는 selectedPostId가 비어 있어 업데이트 불가")
            return
        }
        
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("Users").document(currentUid).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let recentPostId = data["recentPostId"] as? String else {
                print("recentPostId 가져오기 실패")
                return
            }

            let postRef = self.db.collection("Rooms")
                .document(self.currentRoomId)
                .collection("posts")
                .document(self.selectedPostId)
            
            let batch = self.db.batch()
            batch.updateData([
                "stickerPostId": recentPostId,
                "stickerType": self.emotion,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: postRef)
            
            batch.commit { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ 스티커 업데이트 실패: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Firestore 스티커 저장 완료: \(self.selectedPostId)에 \(recentPostId) 스티커 붙임")
                
                // 🎯 로컬 상태도 즉시 업데이트
                self.downloadStickerImage(stickerPostId: recentPostId, roomId: self.currentRoomId, stickerType: self.emotion) { stickerImage in
                    DispatchQueue.main.async {
                        // postId로 게시물 찾기
                        guard let index = self.displayablePosts.firstIndex(where: { $0.postId == self.selectedPostId }) else {
                            print("⚠️ 게시물을 찾을 수 없습니다")
                            return
                        }
                        
                        let existingPost = self.displayablePosts[index]
                        let newPostData = PostData(
                            postId: existingPost.postId,
                            uid: existingPost.uid,
                            frontImageURL: existingPost.post.frontImageURL,
                            backImageURL: existingPost.post.backImageURL,
                            caption: existingPost.caption,
                            stickerPostId: recentPostId,
                            stickerType: self.emotion
                        )
                        
                        self.displayablePosts[index] = DisplayablePost(
                            post: newPostData,
                            frontImage: existingPost.frontImage,
                            backImage: existingPost.backImage,
                            stickerImage: stickerImage,
                            nickname: existingPost.nickname,
                            isMyPost: existingPost.isMyPost
                        )
                        print("✅ 로컬 UI 업데이트 완료: 스티커 표시됨")
                    }
                }
            }
        }
    }
    
    func removeStickerData() {
        guard !currentRoomId.isEmpty, !selectedPostId.isEmpty else {
            print("currentRoomId 또는 selectedPostId가 비어 있어 삭제 불가")
            return
        }
        
        let postRef = db.collection("Rooms")
            .document(currentRoomId)
            .collection("posts")
            .document(selectedPostId)
        
        let batch = db.batch()
        batch.updateData([
            "stickerPostId": "",
            "stickerType": FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: postRef)
        
        batch.commit { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 스티커 삭제 실패: \(error.localizedDescription)")
                return
            }
            
            print("✅ Firestore 스티커 삭제 완료: \(self.selectedPostId)")
            
            // 🎯 로컬 상태도 즉시 업데이트
            DispatchQueue.main.async {
                guard let index = self.displayablePosts.firstIndex(where: { $0.postId == self.selectedPostId }) else {
                    print("⚠️ 게시물을 찾을 수 없습니다")
                    return
                }
                
                let existingPost = self.displayablePosts[index]
                let newPostData = PostData(
                    postId: existingPost.postId,
                    uid: existingPost.uid,
                    frontImageURL: existingPost.post.frontImageURL,
                    backImageURL: existingPost.post.backImageURL,
                    caption: existingPost.caption,
                    stickerPostId: "",
                    stickerType: nil
                )
                
                self.displayablePosts[index] = DisplayablePost(
                    post: newPostData,
                    frontImage: existingPost.frontImage,
                    backImage: existingPost.backImage,
                    stickerImage: nil,
                    nickname: existingPost.nickname,
                    isMyPost: existingPost.isMyPost
                )
                print("✅ 로컬 UI 업데이트 완료: 스티커 제거됨")
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
        getStickerData()
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
                                self?.downloadAllTodayImages(posts: todayPosts, roomId: roomId)
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
    
    private func downloadAllTodayImages(posts: [PostData], roomId: String) {
        print("🖼️ 모든 게시물 이미지 다운로드 시작 (roomId: \(roomId))")
        displayablePosts = []
        
        // 현재 사용자 UID 가져오기
        let currentUserUid = Auth.auth().currentUser?.uid ?? ""
        
        let group = DispatchGroup()
        var tempDisplayablePosts: [Int: DisplayablePost] = [:]  // 인덱스와 함께 저장
        
        for (index, post) in posts.enumerated() {
            group.enter()
            
            // 내 게시물인지 확인
            let isMyPost = (post.uid == currentUserUid)
            let imageGroup = DispatchGroup()
            
            // 각 데이터를 저장할 변수들
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
                // 기본 이미지와 닉네임으로 DisplayablePost 생성 (스티커 없이)
                if let front = frontImage, let back = backImage {
                    let displayablePost = DisplayablePost(
                        post: post,
                        frontImage: front,
                        backImage: back,
                        stickerImage: nil,  // 일단 nil로 생성
                        nickname: nickname,
                        isMyPost: isMyPost
                    )
                    tempDisplayablePosts[index] = displayablePost
                    print("✅ 게시물 \(index + 1) 기본 이미지 다운로드 완료")
                    
                    // 🎯 스티커가 있으면 별도로 다운로드 후 업데이트
                    if !post.stickerPostId.isEmpty {
                        print("🎯 스티커 다운로드 시작: \(post.stickerPostId) for post \(post.postId)")
                        self.downloadStickerImage(stickerPostId: post.stickerPostId, roomId: roomId, stickerType: post.stickerType) { [weak self] stickerImg in
                            guard let self = self, let sticker = stickerImg else { return }
                            
                            DispatchQueue.main.async {
                                // 스티커 다운로드 완료 후 displayablePosts 업데이트
                                if let idx = self.displayablePosts.firstIndex(where: { $0.postId == post.postId }) {
                                    let updatedPost = DisplayablePost(
                                        post: self.displayablePosts[idx].post,
                                        frontImage: self.displayablePosts[idx].frontImage,
                                        backImage: self.displayablePosts[idx].backImage,
                                        stickerImage: sticker,
                                        nickname: self.displayablePosts[idx].nickname,
                                        isMyPost: self.displayablePosts[idx].isMyPost
                                    )
                                    self.displayablePosts[idx] = updatedPost
                                    print("✅ 게시물 \(index + 1) 스티커 추가 완료!")
                                }
                            }
                        }
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // 인덱스 순서대로 정렬하여 배열로 변환
            let sortedPosts = tempDisplayablePosts.sorted(by: { $0.key < $1.key }).map { $0.value }
            self.displayablePosts = sortedPosts
            print("🎉 모든 게시물 기본 이미지 다운로드 완료: \(sortedPosts.count)개 (스티커는 별도 로딩)")
            
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

    
    private func downloadStickerImage(stickerPostId: String, roomId: String, stickerType: String?, completion: @escaping (UIImage?) -> Void) {
        // Firestore 조회
        db.collection("Rooms")
            .document(roomId)
            .collection("posts")
            .document(stickerPostId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else {
                    completion(nil)
                    return
                }
                
                if let error = error {
                    print("❌ 스티커 게시물 정보 가져오기 실패: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let frontImageURL = data["frontImageURL"] as? String else {
                    print("❌ 스티커 이미지 URL 없음")
                    completion(nil)
                    return
                }
                
                self.photoSaveService.downloadImage(from: frontImageURL) { result in
                    switch result {
                    case .success(let image):
                        DispatchQueue.global(qos: .userInitiated).async {
                            let localImageUtils = ImageUtils()
                            
                            _ = localImageUtils.makeMask(from: image)
                            
                            guard let stickerImage = localImageUtils.makeSticker(with: image) else {
                                print("❌ 스티커 변환 실패: \(stickerPostId)")
                                DispatchQueue.main.async {
                                    completion(nil)
                                }
                                return
                            }
                            

                            if let emotion = stickerType {
                                let borderColor = self.borderColor(for: emotion)
                                if let borderedSticker = stickerImage.addBorder(thickness: 4, color: borderColor) {
                                    print("✅ 스티커 처리 완료: \(stickerPostId) - \(emotion)")
                                    DispatchQueue.main.async {
                                        completion(borderedSticker)
                                    }
                                } else {
                                    print("❌ 테두리 추가 실패: \(stickerPostId)")
                                    DispatchQueue.main.async {
                                        completion(stickerImage)
                                    }
                                }
                            } else {
                                print("✅ 스티커 변환 완료: \(stickerPostId)")
                                DispatchQueue.main.async {
                                    completion(stickerImage)
                                }
                            }
                        }
                    case .failure(let error):
                        print("❌ 스티커 이미지 다운로드 실패: \(error.localizedDescription)")
                        completion(nil)
                    }
                }
            }
    }
    
    private func borderColor(for emotion: String) -> UIColor {
        switch emotion {
        case "사랑해":
            return .ddFeelingPink
        case "멋지다":
            return .ddFeelingYellow
        case "뭐야?":
            return .ddFeelingGreen
        case "화나":
            return .ddFeelingOrange
        case "슬퍼":
            return .ddFeelingBlue
        default:
            return .ddGray700
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
