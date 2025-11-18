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
    @Published var todayPosts: [HomePost] = []
    @Published var currentPost: HomePost?
    @Published var isLoading: Bool = false
    @Published var isShowCameraView: Bool = false
    
    let connectUserInfo = UserPairingStore.shared
    private let dataManager: DataManagerProtocol = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var timeCheckTimer: Timer?
    
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
    
    func loadPosts() async {
        await MainActor.run { isLoading = true }
        
        guard let roomId = connectUserInfo.roomId, let myUid = connectUserInfo.myUid else {
            await MainActor.run { isLoading = false }
            return
        }
        
        do {
            let posts: [PostData] = try await dataManager.fetchCollection(path: "Rooms/\(roomId)/posts", orderBy: "createdAt", descending: true)
            
            let homePosts = await convertToHomePosts(posts: posts, myUid: myUid)
            
            let todayPosts = HomePost.todayPosts(from: homePosts)
            
            await MainActor.run {
                self.todayPosts = todayPosts
                self.isLoading = false
            }
        } catch {
            print("게시물 로드 실패: \(error.localizedDescription)")
            await MainActor.run { isLoading = false }
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
    
    func togglePostType() {
        isShowingMyPost.toggle()
        currentIndex = 0
    }
    
    func didStartUploading() {
        isLoading = true
    }
    
    func didUploadPost() {
        isLoading = false
        selectedPostType = .myArchive
        Task {
            await loadPosts()
        }
    }
    
    deinit {
        timeCheckTimer?.invalidate()
    }
}
