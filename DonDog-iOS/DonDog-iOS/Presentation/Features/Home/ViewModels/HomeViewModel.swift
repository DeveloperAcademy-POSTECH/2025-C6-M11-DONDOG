//
//  HomeViewModel.swift
//  DonDog-iOS
//
//  Created by Ito on 11/5/25.
//

import Combine
import SwiftUI

final class HomeViewModel: ObservableObject, CaptionViewModelDelegate {
    @Published var currentIndex: Int = 0
    @Published var isShowingMyPost: Bool = false
    @Published var selectedPostType: ArchiveSegment = .partnerArchive {
        didSet {
            isShowingMyPost = selectedPostType == .myArchive
            currentIndex = 0
        }
    }
    @Published var isShowingATimePost: Bool = true {
        didSet {
            updateTimeTypeFromCurrentTime()
        }
    }
    @Published var localFrontImage: UIImage?
    @Published var localBackImage: UIImage?
    @Published var localCaption: String?
    @Published var localUploadDate: Date?
    
    @Published var isUploadingLocalImage: Bool = false
    @Published var isSyncingUploadedPost: Bool = false
    
    @Published var todayPosts: [HomePost] = []
    @Published var currentPost: HomePost?
    @Published var isLoading: Bool = false
    @Published var isShowCameraView: Bool = false
    @Published var isShowStickerSheet: Bool = false
    @Published var isEditingStickers: Bool = false
    @Published var isShowToast: Bool = false
    @Published var toastMessage: String = ""
    
    let connectUserInfo = UserPairingStore.shared
    private let dataManager: DataManagerProtocol = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var timeCheckTimer: Timer?
    
    var shouldShowLocalUploadedPost: Bool {
        (isUploadingLocalImage || isSyncingUploadedPost) &&
        selectedPostType == .myArchive &&
        localFrontImage != nil &&
        localBackImage != nil
    }
    
    init() {
        updateTimeTypeFromCurrentTime()
        timeCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateTimeTypeFromCurrentTime()
        }
        
        connectUserInfo.$isConnected
            .dropFirst()
            .sink { [weak self] state in
                guard state == .connected else { return }
                Task {
                    await self?.loadPosts()
                }
            }
            .store(in: &cancellables)
        
        if connectUserInfo.isConnected == .connected {
            Task {
                await loadPosts()
            }
        }
        
        $todayPosts
            .combineLatest($isShowingMyPost, $isShowingATimePost)
            .map { [weak self] posts, isShowingMyPost, isShowingATimePost in
                self?.updateCurrentPost(posts: posts, isShowingMyPost: isShowingMyPost, isShowingATimePost: isShowingATimePost)
            }
            .assign(to: &$currentPost)
    }
    
    @discardableResult
    func loadPosts() async -> Bool {
        isLoading = true
        
        guard let roomId = connectUserInfo.roomId, let myUid = connectUserInfo.myUid else {
            isLoading = false
            return false
        }
        
        do {
            let posts: [PostData] = try await dataManager.fetchCollection(path: "Rooms/\(roomId)/posts", orderBy: "createdAt", descending: true)
            
            let homePosts = await convertToHomePosts(posts: posts, myUid: myUid)
            
            let todayPosts = HomePost.todayPosts(from: homePosts)
            
            self.todayPosts = todayPosts
            self.isLoading = false
            return true
        } catch {
            print("게시물 로드 실패: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    private func convertToHomePosts(posts: [PostData], myUid: String) async -> [HomePost] {
        return posts.map { postData in
            HomePost(post: postData, frontImageURL: postData.frontURL, backImageURL: postData.backURL, authorId: postData.authorId, isMyPost: postData.authorId == myUid)
        }
    }
    
    private func updateCurrentPost(posts: [HomePost], isShowingMyPost: Bool, isShowingATimePost: Bool) -> HomePost? {
        let targetUser = isShowingMyPost
        let targetTimeType: TimeType = isShowingATimePost ? .a : .b
        
        return posts
            .filter { $0.isMyPost == targetUser && $0.timeType == targetTimeType }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    private func updateTimeTypeFromCurrentTime() {
        let currentIsATime = DateUtils.isATime(date: Date())
        if isShowingATimePost != currentIsATime {
            DispatchQueue.main.async { [weak self] in
                self?.isShowingATimePost = currentIsATime
            }
        }
    }
    
    func checkAndShowCamera() {
        let currentIsATime = DateUtils.isATime(date: Date())
        let currentTimeType: TimeType = currentIsATime ? .a : .b
        
        // 오늘 게시물 중 내 게시물이고 현재 시간대에 해당하는 게시물이 있는지 확인
        let hasPostInCurrentTime = todayPosts.contains { post in
            post.isMyPost && post.timeType == currentTimeType
        }
        
        if hasPostInCurrentTime {
            let timeString = currentIsATime ? "오전" : "오후"
            toastMessage = "\(timeString) 게시물을 이미 올렸어요!"
            isShowToast = true
            
            // 2초 후 토스트 자동 숨김
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.isShowToast = false
                }
            }
        } else {
            isShowCameraView = true
        }
    }
    
    func togglePostType() {
        isShowingMyPost.toggle()
        currentIndex = 0
    }
    
    func didStartUploading(frontImage: UIImage?, backImage: UIImage?, caption: String) {
        isLoading = true
        isUploadingLocalImage = true
        isSyncingUploadedPost = false
        localFrontImage = frontImage
        localBackImage = backImage
        localCaption = caption
        localUploadDate = Date()
        selectedPostType = .myArchive
    }
    
    func didFinishUploading(result: CaptionUploadResult) {
        isLoading = false
        
        switch result {
        case .success:
            isUploadingLocalImage = false
            isSyncingUploadedPost = true
            Task {
                let didSyncServerPost = await loadPosts()
                
                if didSyncServerPost {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSyncingUploadedPost = false
                        clearLocalUploadedPost()
                    }
                } else {
                    isSyncingUploadedPost = false
                }
            }
        case .failure(let message):
            isUploadingLocalImage = false
            isSyncingUploadedPost = false
            clearLocalUploadedPost()
            toastMessage = "업로드에 실패했어요: \(message)"
            isShowToast = true
        }
    }
    
    private func clearLocalUploadedPost() {
        localFrontImage = nil
        localBackImage = nil
        localCaption = nil
        localUploadDate = nil
    }
    
    deinit {
        timeCheckTimer?.invalidate()
    }
}
