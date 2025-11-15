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

    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    var hasPreviousDisplayMonth: Bool {
        guard !displayMonths.isEmpty else { return false }
        return currentMonthIndex < displayMonths.count - 1
    }

    var hasNextDisplayMonth: Bool {
        guard !displayMonths.isEmpty else { return false }
        return currentMonthIndex > 0
    }
    
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
    func moveToPost(day: ArchiveDay) {
        Task { @MainActor in
            guard let roomId = connectUserInfo.roomId, !roomId.isEmpty else { return }
            isLoading = true
            defer { isLoading = false }
            do {
                let post: PostData = try await dataManager.fetch(
                    path: "Rooms/\(roomId)/posts/\(day.postId)"
                )
                coordinator?.push(.post(post: post, postType: .archive))
            } catch {
                print("Post 로드 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // 전체 기록 가져오기
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
    
    func fetchMonthlyArchives() async {
        await MainActor.run { isLoading = true }
        
        let allPosts = await fetchAllPosts()
        
        await MainActor.run {
            self.allPosts = allPosts
            updateDisplayArchives()
            self.isLoading = false
        }
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
    
    // 게시물 업로드 3일 초과시 처리
    func isPostBlurred(for day: ArchiveDay) -> Bool {
        let isOver3Days = DateUtils.isOver3daysSinceLastUpload()
        let isPartnerArchive = selectedAuthorType == .partnerArchive
        let lastUploadedAt = connectUserInfo.lastUploadedAt ?? Date()
        
        return isOver3Days && isPartnerArchive && day.date > lastUploadedAt
    }
}
