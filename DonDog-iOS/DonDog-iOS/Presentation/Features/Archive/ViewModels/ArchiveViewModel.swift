//
//  ArchiveViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/11/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

final class ArchiveViewModel: ObservableObject {
    let connectUserInfo = UserPairingStore.shared
    private let archiveCache = ArchiveCache.shared
    private weak var coordinator: AppCoordinator?
    private let dataManager: DataManagerProtocol = DataManager.shared
    
    @Published var archiveMonths: [ArchiveMonth] = []
    @Published var displayMonths: [ArchiveMonth] = []
    @Published var allPosts: [PostData] = []
    @Published var totalPostCount: Int = 0
    @Published var isLoading = false
    @Published var currentMonthIndex: Int = 0
    @Published var selectedAuthorType: ArchiveSegment = .partnerArchive {
        didSet { updateDisplayArchives() }
    }
    
    // MARK: - 사용자 상호작용
    func goToPreviousMonth() {
        if currentMonthIndex < displayMonths.count - 1 {
            currentMonthIndex += 1
        }
    }
    
    func goToNextMonth() {
        if currentMonthIndex > 0 {
            currentMonthIndex -= 1
        }
    }
    
    // 각 Post로 이동
    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    func moveToPost(day: ArchiveDay) {
        Task {
            if let post = allPosts.first(where: { $0.postId == day.postId }) {
                coordinator?.push(.archiveDetail(post: post, postType: .archive))
                return
            }
            
            guard let roomId = connectUserInfo.roomId, !roomId.isEmpty else { return }
            do {
                let post: PostData = try await dataManager.fetch(
                    path: "Rooms/\(roomId)/posts/\(day.postId)"
                )
                coordinator?.push(.archiveDetail(post: post, postType: .archive))
            } catch {
                print("Post 로드 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - posts 데이터 가져오기
    func updateMonthlyArchives() async {
        guard let roomId = connectUserInfo.roomId, !roomId.isEmpty else {
            await archiveCache.clear()
            await MainActor.run {
                self.allPosts = []
                updateDisplayArchives()
                self.isLoading = false
            }
            return
        }
        
        let snapshot = await archiveCache.snapshot(for: roomId)
        let cachedPosts = snapshot.posts
        let localLastCreatedAt = snapshot.lastPostCreatedAt
        
        /// 캐싱이 있으면 즉시 표시 (로딩 없이 복귀)
        self.allPosts = cachedPosts
        updateDisplayArchives()
        self.isLoading = false
        
        /// A 서버에서 전부 가져오기 (캐시가 없거나, 캐시에 최신 시간이 없는 경우)
        if cachedPosts.isEmpty || localLastCreatedAt == nil {
            isLoading = true
            let allPosts = await fetchAllPosts()
            await archiveCache.update(roomId: roomId, with: allPosts)
            
            self.allPosts = allPosts
            updateDisplayArchives()
            self.isLoading = false
            return
        }
        
        let serverLastCreatedAt = await fetchLatestPostCreatedAt()
        
        /// B 캐싱 그대로 사용하기 (서버에서 최신 시간을 못 가져오거나, 서버=캐싱이라면)
        guard let server = serverLastCreatedAt else { return }
        if let local = localLastCreatedAt, server.dateValue() <= local.dateValue() {
            return
        }
        
        /// C 캐싱안된것 가져오기 (서버에 새 글이 있는 경우)
        guard let local = localLastCreatedAt else { return }
        let newPosts = await fetchPosts(after: local)
        await archiveCache.merge(roomId: roomId, newPosts: newPosts)
        
        /// 최종: 캐싱된 것 UI에 보여주기
        let merged = await archiveCache.snapshot(for: roomId).posts
        await MainActor.run {
            self.allPosts = merged
            updateDisplayArchives()
            self.isLoading = false
        }
    }
    
    /// 서버의 가장 최근 게시물 날짜 가져오기
    private func fetchLatestPostCreatedAt() async -> Timestamp? {
        guard let roomId = connectUserInfo.roomId, !roomId.isEmpty else {
            return nil
        }
        
        do {
            let posts: [PostData] = try await dataManager.fetchCollection(
                path: "Rooms/\(roomId)/posts",
                orderBy: "createdAt",
                descending: true,
                limit: 1
            )
            return posts.first?.createdAt
        } catch {
            print("최신 Post 조회 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    // A 전체 기록 가져오기
    private func fetchAllPosts() async -> [PostData] {
        guard let roomId = connectUserInfo.roomId, !roomId.isEmpty else {
            return []
        }
        
        do {
            let posts: [PostData] = try await dataManager.fetchCollection(
                path: "Rooms/\(roomId)/posts",
                orderBy: "createdAt",
                descending: false
            )
            return posts
        } catch {
            print("DataManager 데이터 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }

    /// C 캐싱 이후~서버 데이터 가져오기
    private func fetchPosts(after lastCreatedAt: Timestamp) async -> [PostData] {
        guard let roomId = connectUserInfo.roomId, !roomId.isEmpty else {
            return []
        }
        
        do {
            let posts: [PostData] = try await dataManager.fetchWhere(
                path: "Rooms/\(roomId)/posts",
                field: "createdAt",
                isGreaterThanOrEqualTo: lastCreatedAt,
                orderBy: "createdAt",
                descending: false
            )
            let lastDate = lastCreatedAt.dateValue()
            return posts.filter { $0.createdAt.dateValue() > lastDate }
        } catch {
            print("증분 Post 조회 실패: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 기본 UIUX
    var hasPreviousDisplayMonth: Bool {
        guard !displayMonths.isEmpty else { return false }
        return currentMonthIndex < displayMonths.count - 1
    }

    var hasNextDisplayMonth: Bool {
        guard !displayMonths.isEmpty else { return false }
        return currentMonthIndex > 0
    }
    
    func selectAuthorType(_ type: ArchiveSegment) {
        selectedAuthorType = type
        updateDisplayArchives()
    }
    
    // 세그먼트 상태에 따른 아카이브 표시
    private func updateDisplayArchives() {
        guard let myId = connectUserInfo.myUid else { return }
        let partnerId = connectUserInfo.partnerUid
        
        let filteredPosts: [PostData]
        
        switch selectedAuthorType {
        case .partnerArchive:
            filteredPosts = allPosts.filter { $0.authorId == partnerId }
        case .myArchive:
            filteredPosts = allPosts.filter { $0.authorId == myId }
        }
        
        let monthDict = processPosts(from: filteredPosts)
        let sorted = sortArchiveMonths(from: monthDict)
        
        if currentMonthIndex >= sorted.count {
            currentMonthIndex = max(0, sorted.count - 1)
        }
        
        displayMonths = sorted
    }
    
    // 월별 아카이브에 필요한 구조로 데이터 정리
    private func processPosts(from posts: [PostData]) -> [String: [ArchiveDay]] {
        var monthDict: [String: [ArchiveDay]] = [:]
        
        for post in posts {
            let date = post.createdAt.dateValue()
            let comps = DateUtils.components(from: date)
            guard let y = comps.year, let m = comps.month, let d = comps.day else { continue }
            let monthKey = "\(y)-\(m)"
            
            guard let thumb = post.thumbnailURL else { continue }
            let dayItem = ArchiveDay(id: post.postId, day: d, thumbnailURL: thumb, postId: post.postId, date: date)
            
            // 월별 배열 초기화
            if monthDict[monthKey] == nil { monthDict[monthKey] = [] }
            
            monthDict[monthKey]?.append(dayItem)
        }
        
        return monthDict
    }

    // 월별 데이터 정렬
    private func sortArchiveMonths(from dict: [String: [ArchiveDay]]) -> [ArchiveMonth] {
        let months: [ArchiveMonth] = dict.compactMap { key, dayArray in
            let parts = key.split(separator: "-")
            guard let y = Int(parts[0]), let m = Int(parts[1]) else { return nil }

            // 같은 달 내에서 같은 날짜일 경우 내림차순
            let sortedDays = dayArray.sorted { lhs, rhs in
                if lhs.day == rhs.day {
                    guard
                        let leftPost = allPosts.first(where: { $0.postId == lhs.postId }),
                        let rightPost = allPosts.first(where: { $0.postId == rhs.postId })
                    else { return false }
                    return leftPost.createdAt.dateValue() > rightPost.createdAt.dateValue()
                } else {
                    // 날짜 내림차순
                    return lhs.day > rhs.day
                }
            }

            return ArchiveMonth(id: key, year: y, month: m, days: sortedDays)
        }
        .sorted {
            ($0.year, $0.month) > ($1.year, $1.month)
        }

        return months
    }
    
    // 현재 달 표시
    var isCurrentMonthDisplayed: Bool {
        guard !displayMonths.isEmpty else { return false }
        let currentDisplayMonth = displayMonths[currentMonthIndex]
        
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        return currentDisplayMonth.year == currentYear && currentDisplayMonth.month == currentMonth
    }
}
