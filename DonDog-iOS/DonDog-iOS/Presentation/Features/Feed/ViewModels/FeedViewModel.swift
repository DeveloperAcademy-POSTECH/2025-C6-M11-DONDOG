//
//  FeedViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import CoreImage
import CoreImage.CIFilterBuiltins
import FirebaseFirestore
import Kingfisher
import UIKit

final class FeedViewModel: ObservableObject, CameraViewModelDelegate, CaptionViewModelDelegate {
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var isAfterUpload = false
    @Published var currentRoomId: String = ""
    @Published var selectedPostId: String = "" {
        didSet {
            checkIsNotMyPost()
        }
    }
    @Published var stickerImage: UIImage?
    @Published var sticker: UIImage?
    @Published var myNickname: String = ""
    @Published var borderedStickers: [String: UIImage] = [:]
    
    @Published var currentPost: PostData?
    @Published var currentNickname: String = ""
    @Published var currentPostIndex: Int = 0
    @Published var displayablePosts: [DisplayablePost] = []
    @Published var emotion: String = "null"
    @Published var isNotMyPost = false
    
    private let dataManager: DataManagerProtocol = FirebaseDataManager.shared
    private let imageUtils = ImageUtils()
    
    init() {
        Task {
            do {
                self.currentRoomId = try await dataManager.getCurrentUserRoomId()
                print("currentRoomId 초기화 완료: \(self.currentRoomId)")
            } catch {
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
        
        Task {
            do {
                let postData: PostData = try await dataManager.fetch(
                    path: "Rooms/\(currentRoomId)/posts/\(selectedPostId)"
                )
                
                guard let currentUid = dataManager.getCurrentUserId() else { return }
                
                await MainActor.run {
                    self.isNotMyPost = postData.uid != currentUid
                }
            } catch {
                print("문서 조회 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func getStickerData() {
        guard let uid = dataManager.getCurrentUserId() else { return }
        
        Task {
            do {
                let user: UserData = try await dataManager.fetch(path: "Users/\(uid)")
                
                guard let recentPostId = user.recentPostId, !recentPostId.isEmpty else {
                    print("recentPostId 없음")
                    return
                }
                
                await MainActor.run {
                    self.myNickname = user.name
                }
                
                let roomId = try await dataManager.getCurrentUserRoomId()
                
                // stickerPostId 선택
                let postIdToFetch: String
                if let currentPost = self.currentPost, !currentPost.stickerPostId.isEmpty {
                    postIdToFetch = currentPost.stickerPostId
                } else if !recentPostId.isEmpty {
                    postIdToFetch = recentPostId
                } else {
                    print("stickerPostId와 recentPostId 모두 없음")
                    return
                }
                
                let postData: PostData = try await dataManager.fetch(
                    path: "Rooms/\(roomId)/posts/\(postIdToFetch)"
                )
                
                self.downloadStickerImage(
                    stickerPostId: postIdToFetch,
                    roomId: roomId,
                    stickerType: postData.stickerType
                ) { [weak self] sticker in
                    DispatchQueue.main.async {
                        if let sticker = sticker {
                            self?.stickerImage = sticker
                            self?.makeStickerAndBordered(from: sticker)
                            print("recentSticker 이미지 로드 성공 (downloadStickerImage)")
                        } else {
                            print("recentSticker 이미지 생성 실패")
                        }
                        self?.emotion = postData.stickerType ?? "null"
                    }
                }
            } catch {
                print("recentPostId 불러오기 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func makeStickerAndBordered(from image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let stickerOnly = self.imageUtils.makeSticker(with: image) else {
                print("스티커 생성 실패")
                return
            }
            
            let emotions = ["사랑해", "멋지다", "뭐야?", "화나", "슬퍼"]
            var borderedDict: [String: UIImage] = [:]
            
            for emotion in emotions {
                let color = FeedViewModel.borderColor(for: emotion)
                if let bordered = stickerOnly.addBorder(thickness: 50, color: color) {
                    borderedDict[emotion] = bordered
                }
            }
            
            DispatchQueue.main.async {
                self.sticker = stickerOnly
                self.borderedStickers = borderedDict
            }
        }
    }
    
    func updateStickerData() {
        guard !currentRoomId.isEmpty, !selectedPostId.isEmpty else {
            print("currentRoomId 또는 selectedPostId가 비어 있어 업데이트 불가")
            return
        }
        
        guard let currentUid = dataManager.getCurrentUserId() else { return }
        
        Task {
            do {
                let user: UserData = try await dataManager.fetch(path: "Users/\(currentUid)")
                guard let recentPostId = user.recentPostId else {
                    print("recentPostId 없음")
                    return
                }
                
                try await dataManager.update(
                    path: "Rooms/\(currentRoomId)/posts/\(selectedPostId)",
                    data: [
                        "stickerPostId": recentPostId,
                        "stickerType": emotion,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                )
                
                let updatedPost: PostData = try await dataManager.fetch(
                    path: "Rooms/\(currentRoomId)/posts/\(selectedPostId)"
                )
                
                let stickerPostId = updatedPost.stickerPostId
                
                self.downloadStickerImage(
                    stickerPostId: stickerPostId,
                    roomId: self.currentRoomId,
                    stickerType: self.emotion
                ) { stickerImage in
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
                            frontImage: existingPost.frontImageURL,
                            backImage: existingPost.backImageURL,
                            stickerImage: stickerImage,
                            nickname: existingPost.nickname,
                            isMyPost: existingPost.isMyPost
                        )
                    }
                }
            } catch {
                print("스티커 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func removeStickerData() {
        guard !currentRoomId.isEmpty, !selectedPostId.isEmpty else {
            print("currentRoomId 또는 selectedPostId가 비어 있어 삭제 불가")
            return
        }
        
        Task {
            do {
                try await dataManager.update(
                    path: "Rooms/\(currentRoomId)/posts/\(selectedPostId)",
                    data: [
                        "stickerPostId": "",
                        "stickerType": FieldValue.delete(),
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                )
                
                print("✅ Firestore 스티커 삭제 완료: \(self.selectedPostId)")
                
                await MainActor.run {
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
                        frontImage: existingPost.frontImageURL,
                        backImage: existingPost.backImageURL,
                        stickerImage: nil,
                        nickname: existingPost.nickname,
                        isMyPost: existingPost.isMyPost
                    )
                    print("✅ 로컬 UI 업데이트 완료: 스티커 제거됨")
                }
            } catch {
                print("❌ 스티커 삭제 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - CaptionViewModelDelegate
    func didUploadPost() {
        print("✅ 게시물 업로드 완료 - FeedView 새로고침")
        
        isAfterUpload = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadTodayPosts()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.getStickerData()
            print("🔄 새 게시물로 스티커 데이터 갱신")
        }
    }
    
    func loadTodayPosts() {
        isLoading = true
        isUploading = false

        Task {
            do {
                let roomId = try await dataManager.getCurrentUserRoomId()
                print("오늘 찍은 Room posts 조회 시작: \(roomId)")

                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let todayTimestamp = Timestamp(date: today)
                print("오늘 날짜: \(today)")

                let todayPosts: [PostData] = try await dataManager.fetchWhere(
                    path: "Rooms/\(roomId)/posts",
                    field: "createdAt",
                    isGreaterThanOrEqualTo: todayTimestamp,
                    orderBy: "createdAt",
                    descending: true
                )

                await MainActor.run {
                    print("📅 오늘 찍은 \(todayPosts.count)개 게시물 로드 완료")
                    if let firstPost = todayPosts.first {
                        self.selectedPostId = firstPost.postId
                        self.currentPost = firstPost
                        self.currentPostIndex = 0
                        self.downloadAllTodayImages(posts: todayPosts, roomId: roomId)
                    } else {
                        print("📭 오늘 찍은 게시물이 없습니다")
                        self.displayablePosts = []
                        self.isLoading = false
                    }
                }
            } catch {
                print("오늘 posts 로드 실패 또는 roomId 가져오기 실패: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func downloadAllTodayImages(posts: [PostData], roomId: String) {
        print("🖼️ 모든 게시물 이미지 다운로드 시작 (roomId: \(roomId))")
        displayablePosts = []
        
        guard let currentUserUid = dataManager.getCurrentUserId() else { return }
        
        let group = DispatchGroup()
        var tempDisplayablePosts: [Int: DisplayablePost] = [:]
        
        for (index, post) in posts.enumerated() {
            group.enter()
            
            let isMyPost = (post.uid == currentUserUid)
            let imageGroup = DispatchGroup()
            
            var frontImageURL: URL?
            var backImageURL: URL?
            var nickname: String = "익명"
            
            frontImageURL = post.frontURL
            backImageURL = post.backURL
            
            imageGroup.enter()
            getUserName(uid: post.uid) { name in
                nickname = name
                imageGroup.leave()
            }
            
            imageGroup.notify(queue: .main) {
                if let front = frontImageURL, let back = backImageURL {
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
                                        frontImage: self.displayablePosts[idx].frontImageURL,
                                        backImage: self.displayablePosts[idx].backImageURL,
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
            
            let finalSortedPosts = sortedPosts.sorted { post1, post2 in
                return post1.createdAt > post2.createdAt
            }
            
            self.displayablePosts = finalSortedPosts
            print("🎉 모든 게시물 기본 이미지 다운로드 완료: \(finalSortedPosts.count)개")
            
            var firstDisplayedPostIndex = 0
            
            if finalSortedPosts.count > 1 && self.isAfterUpload {
                firstDisplayedPostIndex = 1
            } else {
                firstDisplayedPostIndex = 0
            }
            
            self.currentPostIndex = firstDisplayedPostIndex
            
            if !finalSortedPosts.isEmpty {
                let initialPost = finalSortedPosts[firstDisplayedPostIndex]
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
                            postsWithStickers[index] = DisplayablePost(
                                post: postsWithStickers[index].post,
                                frontImage: postsWithStickers[index].frontImageURL,
                                backImage: postsWithStickers[index].backImageURL,
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
                self.displayablePosts = postsWithStickers
                print("🎉 모든 스티커 다운로드 완료!")
                
                self.isLoading = false
                self.isUploading = false
                print("✅ 로딩 완료!")
                
                if self.isAfterUpload && self.displayablePosts.count > 1 && self.currentPostIndex == 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.currentPostIndex = 0
                        self.isAfterUpload = false
                    }
                } else {
                    self.isAfterUpload = false
                }
            }
        }
    }
    
    private func getUserName(uid: String, completion: @escaping (String) -> Void) {
        Task {
            do {
                let user: UserData = try await dataManager.fetch(path: "Users/\(uid)")
                completion(user.name)
            } catch {
                print("사용자 이름 가져오기 실패: \(error.localizedDescription)")
                completion("익명")
            }
        }
    }
    
    private func downloadStickerImage(stickerPostId: String, roomId: String, stickerType: String?, completion: @escaping (UIImage?) -> Void) {
        Task {
            do {
                let postData: PostData = try await dataManager.fetch(
                    path: "Rooms/\(roomId)/posts/\(stickerPostId)"
                )
                
                guard let url = URL(string: postData.frontImageURL) else {
                    print("스티커 이미지 URL 생성 실패")
                    completion(nil)
                    return
                }
                
                KingfisherManager.shared.retrieveImage(with: url) { result in
                    switch result {
                    case .success(let value):
                        let image = value.image
                        DispatchQueue.global(qos: .userInitiated).async {
                            let utils = ImageUtils()
                            
                            guard let stickerOnly = utils.makeSticker(with: image) else {
                                print("스티커 변환 실패: \(stickerPostId)")
                                DispatchQueue.main.async { completion(nil) }
                                return
                            }
                            
                            if let emotion = stickerType {
                                let borderColor = FeedViewModel.borderColor(for: emotion)
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
                        print("KF 스티커 이미지 조회 실패: \(error.localizedDescription)")
                        completion(nil)
                    }
                }
            } catch {
                print("스티커 게시물 정보 가져오기 실패: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    static func borderColor(for emotion: String) -> UIColor {
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
    
    func updateCurrentPost(at index: Int) {
        guard index >= 0 && index < displayablePosts.count else { return }
        
        let displayablePost = displayablePosts[index]
        
        currentPostIndex = index
        currentPost = displayablePost.post
        selectedPostId = displayablePost.postId
        currentNickname = displayablePost.nickname
    }
}
