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
    
    private var stickers: [String: UIImage] = [:]
    @Published var stickerCache: [String: [String: UIImage]] = [:]
    
    @Published var currentPost: PostData?
    @Published var currentUserName: String = ""
    @Published var currentPostIndex: Int = 0
    @Published var displayablePosts: [DisplayablePost] = []
    @Published var type: String = "null"
    @Published var isNotMyPost = false
    
    private let dataManager: DataManagerProtocol = DataManager.shared
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
                    self.isNotMyPost = postData.authorId != currentUid
                }
            } catch {
                print("문서 조회 실패: \(error.localizedDescription)")
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
                        "stickerType": type,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                )
                
                let updatedPost: PostData = try await dataManager.fetch(
                    path: "Rooms/\(currentRoomId)/posts/\(selectedPostId)"
                )
                
                let stickerPostId = updatedPost.stickerPostId
            
                    DispatchQueue.main.async {
                        guard let index = self.displayablePosts.firstIndex(where: { $0.postId == self.selectedPostId }) else {
                            print("게시물을 찾을 수 없습니다")
                            return
                        }
                        
                        let existingPost = self.displayablePosts[index]
                        let newPostData = PostData(
                            postId: existingPost.postId,
                            authorId: existingPost.uid,
                            frontImageURL: existingPost.post.frontImageURL,
                            backImageURL: existingPost.post.backImageURL,
                            caption: existingPost.caption,
                            createdAt: existingPost.post.createdAt,
                            stickerPostId: recentPostId,
                            stickerType: self.type
                        )
                        
                        self.displayablePosts[index] = DisplayablePost(
                            post: newPostData,
                            frontImage: existingPost.frontImageURL,
                            backImage: existingPost.backImageURL,
                            nickname: existingPost.nickname,
                            isMyPost: existingPost.isMyPost
                        )
                    }
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
                        authorId: existingPost.uid,
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
    
    // TODO: 기존 downloadAllTodayImages 함수, 100줄 이상 린트 오류 걸려서 buildDisplayablePost 두개로 분리
    private func downloadAllTodayImages(posts: [PostData], roomId: String) {
        print("🖼️ 모든 게시물 이미지 다운로드 시작 (roomId: \(roomId))")
        displayablePosts = []
        
        guard let currentUserUid = dataManager.getCurrentUserId() else { return }
        
        let group = DispatchGroup()
        var tempDisplayablePosts: [Int: DisplayablePost] = [:]
        
        for (index, post) in posts.enumerated() {
            group.enter()
            buildDisplayablePost(index: index,
                                 post: post,
                                 roomId: roomId,
                                 currentUserUid: currentUserUid) { idx, displayable, stickerPostId, stickerType in
                tempDisplayablePosts[idx] = displayable
                
                DispatchQueue.main.async {
                    if let currentIndex = self.displayablePosts.firstIndex(where: { $0.postId == displayable.postId }) {
                        let updated = DisplayablePost(
                            post: self.displayablePosts[currentIndex].post,
                            frontImage: self.displayablePosts[currentIndex].frontImageURL,
                            backImage: self.displayablePosts[currentIndex].backImageURL,
                            nickname: self.displayablePosts[currentIndex].nickname,
                            isMyPost: self.displayablePosts[currentIndex].isMyPost
                        )
                        self.displayablePosts[currentIndex] = updated
                        print("✅ 게시물 \(idx + 1) 스티커 추가 완료!")
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let sortedPosts = tempDisplayablePosts.sorted(by: { $0.key < $1.key }).map { $0.value }
            let finalSortedPosts = sortedPosts.sorted { $0.createdAt > $1.createdAt }
            
            self.applyInitialSelectionAndIndices(finalSortedPosts)
            
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

    private func buildDisplayablePost(index: Int, post: PostData, roomId: String, currentUserUid: String, completion: @escaping (Int, DisplayablePost, String?, String?) -> Void) {
        let isMyPost = (post.authorId == currentUserUid)
        var nickname: String = "익명"
        
        let frontImageURL: URL? = post.frontURL
        let backImageURL: URL? = post.backURL
        
        let imageGroup = DispatchGroup()
        imageGroup.enter()
        fetchUserName(uid: post.authorId) { name in
            nickname = name
            imageGroup.leave()
        }
        
        imageGroup.notify(queue: .main) {
            if let front = frontImageURL, let back = backImageURL {
                let displayablePost = DisplayablePost(
                    post: post,
                    frontImage: front,
                    backImage: back,
                    nickname: nickname,
                    isMyPost: isMyPost
                )
                print("✅ 게시물 \(index + 1) 기본 이미지 다운로드 완료")
                completion(index, displayablePost, post.stickerPostId.isEmpty ? nil : post.stickerPostId, post.stickerType)
            } else {
                let displayablePost = DisplayablePost(
                    post: post,
                    frontImage: frontImageURL ?? URL(fileURLWithPath: "/dev/null"),
                    backImage: backImageURL ?? URL(fileURLWithPath: "/dev/null"),
                    nickname: nickname,
                    isMyPost: isMyPost
                )
                print("⚠️ 이미지 URL 누락: \(index + 1)")
                completion(index, displayablePost, post.stickerPostId.isEmpty ? nil : post.stickerPostId, post.stickerType)
            }
        }
    }

    private func applyInitialSelectionAndIndices(_ finalSortedPosts: [DisplayablePost]) {
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
            self.currentUserName = initialPost.nickname
            self.selectedPostId = initialPost.postId
            self.currentPost = initialPost.post
        }
    }
    
    private func fetchUserName(uid: String, completion: @escaping (String) -> Void) {
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
    
    func preloadStickers() {
        for post in displayablePosts {
            Task {
                let stickers = await StickerService().getStickerCollection(of: post.postId)
                await MainActor.run {
                    self.stickerCache[post.postId] = stickers
                }
            }
        }
    }

    func updateCurrentPost(at index: Int) {
        guard index >= 0 && index < displayablePosts.count else { return }
        
        let displayablePost = displayablePosts[index]
        currentPostIndex = index
        currentPost = displayablePost.post
        selectedPostId = displayablePost.postId
        
        // 캐시에서 가져오기
        if let cached = stickerCache[displayablePost.postId] {
            self.stickers = cached
        } else {
            Task {
                let newStickers = await StickerService().getStickerCollection(of: displayablePost.postId)
                await MainActor.run {
                    self.stickers = newStickers
                    self.stickerCache[displayablePost.postId] = newStickers
                }
            }
        }
    }
}
