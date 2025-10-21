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
import CoreImage
import CoreImage.CIFilterBuiltins

final class FeedViewModel: ObservableObject, CameraViewModelDelegate, CaptionViewModelDelegate {
    @Published var selectedFrontImage: UIImage?
    @Published var selectedBackImage: UIImage?
    @Published var postsList: [PostData] = []
    @Published var images: [PostData] = []
    @Published var todayPost: PostData?
    @Published var todayFrontImage: UIImage?
    @Published var todayBackImage: UIImage?
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadStatus: String = ""
    @Published var currentRoomId: String = ""
    @Published var selectedPostId: String = "" {
        didSet {
            checkIsNotMyPost()
        }
    }
    
    @Published var stickerImage: UIImage?
    @Published var sticker: UIImage?
    @Published var myNickname: String = ""
    private var mask: UIImage?
    @Published var frame: UIImage?
    @Published var borderedStickers: [String: UIImage] = [:]
    
    @Published var currentPost: PostData?
    @Published var currentNickname: String = ""
    @Published var currentPostIndex: Int = 0
    @Published var displayablePosts: [DisplayablePost] = []
    @Published var emotion: String = "null"
    @Published var isNotMyPost = false
    
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
            
            DispatchQueue.main.async {
                        if let name = data["name"] as? String {
                            self.myNickname = name
                        }
                    }

            self.photoSaveService.getCurrentUserRoomId { result in
                switch result {
                case .success(let roomId):
                    let basePostRef = self.db.collection("Rooms").document(roomId)
                        .collection("posts")
                    
                    // stickerPostId 선택
                    let postIdToFetch: String
                    if let currentPost = self.currentPost,
                       !currentPost.stickerPostId.isEmpty {
                        postIdToFetch = currentPost.stickerPostId
                    } else if !recentPostId.isEmpty {
                        postIdToFetch = recentPostId
                    } else {
                        print("stickerPostId와 recentPostId 모두 없음")
                        return
                    }
                    
                    let postRef = basePostRef.document(postIdToFetch)
                    
                    postRef.getDocument { snapshot, error in
                        if let error = error {
                            print("sticker로 쓸 postId 문서 조회 실패: \(error.localizedDescription)")
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
                                    
                                    self?.makeStickerAndBordered(from: image)
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
    
    func makeStickerAndBordered(from image: UIImage) {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                let maskImage = self.imageUtils.makeMask(from: image)
                
                guard let stickerOnly = self.imageUtils.makeSticker(with: image) else {
                    print("스티커 생성 실패")
                    return
                }
                
                let emotions = ["사랑해", "멋지다", "뭐야?", "화나", "슬퍼"]
                var borderedDict: [String: UIImage] = [:]
                
                for emotion in emotions {
                    let color = self.borderColor(for: emotion)
                    if let bordered = stickerOnly.addBorder(thickness: 50, color: color) {
                        borderedDict[emotion] = bordered
                    }
                }
                
                DispatchQueue.main.async {
                    self.mask = maskImage
                    self.sticker = stickerOnly
                    self.borderedStickers = borderedDict
                }
            }
        }
        
    func sticker(for emotion: String) -> UIImage? {
            return borderedStickers[emotion] ?? sticker
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
                    print("스티커 업데이트 실패: \(error.localizedDescription)")
                    return
                }
                
                postRef.getDocument { snapshot, error in
                    if let data = snapshot?.data() {
                        let stickerPostId = data["stickerPostId"] as? String ?? recentPostId
                        
                        self.downloadStickerImage(stickerPostId: stickerPostId, roomId: self.currentRoomId, stickerType: self.emotion) { stickerImage in
                            DispatchQueue.main.async {
                                guard let index = self.displayablePosts.firstIndex(where: { $0.postId == self.selectedPostId }) else {
                                    print("게시물을 찾을 수 없습니다")
                                    return
                                }
                                
                                let existingPost = self.displayablePosts[index]
                                let newPostData = PostData(
                                    postId: existingPost.postId,
                                    uid: existingPost.uid,
                                    frontImageURL: existingPost.post.frontImageURL,
                                    backImageURL: existingPost.post.backImageURL,
                                    caption: existingPost.caption,
                                    createdAt: existingPost.post.createdAt,
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
                            }
                        }
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
                    createdAt: existingPost.post.createdAt,
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
        // ⚠️ 여기서 loadTodayPosts() 호출하지 말고, 타이밍 조절을 위해 약간 딜레이
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadTodayPosts()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.getStickerData()
                print("🔄 새 게시물로 스티커 데이터 갱신")
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

    
//    func loadTodayPosts() {
//        isLoading = true
//        photoSaveService.getCurrentUserRoomId { [weak self] result in
//            switch result {
//            case .success(let roomId):
//                self?.photoSaveService.fetchTodayRoomPosts(roomId: roomId) { result in
//                    DispatchQueue.main.async {
//                        // ⚠️ 여기서 isLoading = false 제거!
//                        switch result {
//                        case .success(let todayPosts):
//                            self?.images = todayPosts
//                            print("📅 오늘 찍은 \(todayPosts.count)개 게시물 로드 완료")
//      
//                            if let firstPost = todayPosts.first {
//                                self?.selectedPostId = firstPost.postId
//                                self?.currentPost = firstPost
//                                self?.currentPostIndex = 0
//                                self?.downloadAllTodayImages(posts: todayPosts, roomId: roomId)
//                            } else {
//                                print("📭 오늘 찍은 게시물이 없습니다")
//                                self?.displayablePosts = []
//                                self?.isLoading = false  // ✅ 게시물이 없을 때만 여기서 false
//                            }
//                        case .failure(let error):
//                            print("오늘 posts 로드 실패: \(error.localizedDescription)")
//                            self?.isLoading = false  // ✅ 실패 시에도 false
//                        }
//                    }
//                }
//            case .failure(let error):
//                print("roomId 가져오기 실패: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    self?.isLoading = false
//                }
//            }
//        }
//    }
    
    func loadTodayPosts() {
        isLoading = true
        isUploading = false  // ✅ 추가: 데이터 로딩 시작하면 업로딩 상태 해제
        photoSaveService.getCurrentUserRoomId { [weak self] result in
            switch result {
            case .success(let roomId):
                self?.photoSaveService.fetchTodayRoomPosts(roomId: roomId) { result in
                    DispatchQueue.main.async {
                        // ⚠️ 여기서 isLoading = false 제거 (이미 수정했을 것)
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
                                self?.isLoading = false
                            }
                        case .failure(let error):
                            print("오늘 posts 로드 실패: \(error.localizedDescription)")
                            self?.isLoading = false
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
        
        let currentUserUid = Auth.auth().currentUser?.uid ?? ""
        
        let group = DispatchGroup()
        var tempDisplayablePosts: [Int: DisplayablePost] = [:]
        
        for (index, post) in posts.enumerated() {
            group.enter()
            
            let isMyPost = (post.uid == currentUserUid)
            let imageGroup = DispatchGroup()
            
            var frontImage: UIImage?
            var backImage: UIImage?
            var nickname: String = "익명"
            
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
            
            imageGroup.enter()
            getUserName(uid: post.uid) { name in
                nickname = name
                imageGroup.leave()
            }
            
            imageGroup.notify(queue: .main) {
                if let front = frontImage, let back = backImage {
                    let displayablePost = DisplayablePost(
                        post: post,
                        frontImage: front,
                        backImage: back,
                        stickerImage: nil,
                        nickname: nickname,
                        isMyPost: isMyPost
                    )
                    tempDisplayablePosts[index] = displayablePost
                    print("✅ 게시물 \(index + 1) 기본 이미지 다운로드 완료")
                    
                    if !post.stickerPostId.isEmpty {
                        print("🎯 스티커 다운로드 시작: \(post.stickerPostId) for post \(post.postId)")
                        self.downloadStickerImage(stickerPostId: post.stickerPostId, roomId: roomId, stickerType: post.stickerType) { [weak self] stickerImg in
                            guard let self = self, let sticker = stickerImg else { return }
                            
                            DispatchQueue.main.async {
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
            let sortedPosts = tempDisplayablePosts.sorted(by: { $0.key < $1.key }).map { $0.value }
            
//            let finalSortedPosts = sortedPosts.sorted { post1, post2 in
//                let hasSticker1 = !post1.stickerPostId.isEmpty
//                let hasSticker2 = !post2.stickerPostId.isEmpty
//                
//                if hasSticker1 != hasSticker2 {
//                    return hasSticker1
//                }
//                
//                return post1.createdAt < post2.createdAt
//            }
            
            let finalSortedPosts = sortedPosts.sorted { post1, post2 in
                return post1.createdAt > post2.createdAt  // ✅ 최신순만
            }
            
            self.displayablePosts = finalSortedPosts
            print("🎉 모든 게시물 기본 이미지 다운로드 완료: \(finalSortedPosts.count)개")
            
            let initialIndex = finalSortedPosts.firstIndex { post in
                post.stickerPostId.isEmpty
            } ?? 0
            
            self.currentPostIndex = initialIndex
            print("📍 초기 TabView 인덱스: \(initialIndex)")
            
            if initialIndex < finalSortedPosts.count {
                let initialPost = finalSortedPosts[initialIndex]
                self.todayFrontImage = initialPost.frontImage
                self.todayBackImage = initialPost.backImage
                self.currentNickname = initialPost.nickname
                self.selectedPostId = initialPost.postId
                self.currentPost = initialPost.post
            }
            
            
            let stickerGroup = DispatchGroup()
            var postsWithStickers: [DisplayablePost] = finalSortedPosts
            
            for (index, post) in finalSortedPosts.enumerated() {
                if !post.stickerPostId.isEmpty {
                    stickerGroup.enter()
                    print("🎯 스티커 다운로드 시작: \(post.stickerPostId) for post \(post.postId)")
                    
                    self.downloadStickerImage(
                        stickerPostId: post.stickerPostId,
                        roomId: roomId,
                        stickerType: post.stickerType
                    ) { stickerImg in
                        if let sticker = stickerImg {
                            // 로컬 배열에 업데이트
                            postsWithStickers[index] = DisplayablePost(
                                post: postsWithStickers[index].post,
                                frontImage: postsWithStickers[index].frontImage,
                                backImage: postsWithStickers[index].backImage,
                                stickerImage: sticker,
                                nickname: postsWithStickers[index].nickname,
                                isMyPost: postsWithStickers[index].isMyPost
                            )
                        }
                        stickerGroup.leave()
                    }
                }
            }
            
            stickerGroup.notify(queue: .main) {
                self.displayablePosts = postsWithStickers  // 스티커 포함된 배열로 재할당
                print("🎉 모든 스티커 다운로드 완료!")
                
                self.isLoading = false
                self.isUploading = false
                print("✅ 로딩 완료!")
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
                    print("스티커 게시물 정보 가져오기 실패: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let frontImageURL = data["frontImageURL"] as? String else {
                    print("스티커 이미지 URL 없음")
                    completion(nil)
                    return
                }
                
                self.photoSaveService.downloadImage(from: frontImageURL) { result in
                    switch result {
                    case .success(let image):
                        DispatchQueue.global(qos: .userInitiated).async {
                            let utils = ImageUtils()
                            
                            _ = utils.makeMask(from: image)
                            
                            guard let stickerOnly = utils.makeSticker(with: image) else {
                                print("스티커 변환 실패: \(stickerPostId)")
                                DispatchQueue.main.async { completion(nil) }
                                return
                            }

                            if let emotion = stickerType {
                                let borderColor = self.borderColor(for: emotion)
                                if let borderedSticker = stickerOnly.addBorder(thickness: 50, color: borderColor) {
                                    DispatchQueue.main.async {
                                        completion(borderedSticker)
                                    }
                                    return
                                } else {
                                    print("테두리 추가 실패, 기본 스티커 반환")
                                }
                            }

                            DispatchQueue.main.async {
                                completion(stickerOnly)
                            }
                        }
                    case .failure(let error):
                        print("스티커 이미지 다운로드 실패: \(error.localizedDescription)")
                        completion(nil)
                    }
                }
            }
    }
    
    private func makeStroke(from mask: CIImage, width: CGFloat, color: CIColor) -> CIImage? {
        let dilateFilter = CIFilter.morphologyMaximum()
        dilateFilter.inputImage = mask
        dilateFilter.radius = Float(width)
        
        guard let dilated = dilateFilter.outputImage else { return nil }
        
        let edge = dilated.applyingFilter("CISubtractBlendMode", parameters: ["inputBackgroundImage": mask])
        
        let colorFilter = CIFilter.multiplyCompositing()
        colorFilter.inputImage = CIImage(color: color).cropped(to: edge.extent)
        colorFilter.backgroundImage = edge
        
        return colorFilter.outputImage
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

