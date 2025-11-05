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
import UIKit

final class ArchiveViewModel: ObservableObject {
    let connectUserInfo = UserPairingStore.shared
    private weak var coordinator: AppCoordinator?
    private let dataManager: DataManagerProtocol = DataManager.shared
    
    @Published var archiveMonths: [ArchiveMonth] = []
    @Published var displayMonths: [ArchiveMonth] = []
    @Published var allPosts: [PostData] = []
    @Published var totalPostCount: Int = 0
    @Published var displayPostCount: Int = 0
    @Published var isLoading = false
    @Published var selectedAuthorType: CustomSegmentedControl.PostAuthorType = .partnerArchive
    @Published var currentMonthIndex: Int = 0
    
    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
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
    
    // 날짜 포매팅
    private func getDate(from month: ArchiveMonth, day: ArchiveDay) -> Date? {
        return DateUtils.date(fromYear: month.year, month: month.month, day: day.day)
    }
    
    func moveToPost(day: ArchiveDay) {
        guard let post = allPosts.first(where: { $0.postId == day.postId }) else { return }

        DispatchQueue.main.async {
            self.coordinator?.push(
                .post(post: post, postType: .archive)
            )
        }
    }
    
    // 전체 기록 가져오기
    func fetchMonthlyArchives() async {
        await MainActor.run { isLoading = true }
        
        let allPosts = await fetchAllPosts()
        
        await MainActor.run {
            self.allPosts = allPosts
            self.totalPostCount = allPosts.count
            updateDisplayArchives()
            self.isLoading = false
        }
    }
    
    func selectAuthorType(_ type: CustomSegmentedControl.PostAuthorType) {
        selectedAuthorType = type
        updateDisplayArchives()
    }
    
    private func updateDisplayArchives() {
        guard let myId = connectUserInfo.myUid else { return }
        let partnerId = connectUserInfo.partnerUid
        
        let filteredPosts: [PostData]
        
        switch selectedAuthorType {
        case .partnerArchive:
            filteredPosts = allPosts.filter { $0.authorId == partnerId}
        case .myArchive:
            filteredPosts = allPosts.filter { $0.authorId == myId}
        }
        
        var monthDict = processPosts(filteredPosts)
        
        let now = Date()
        let comps = DateUtils.components(from: now)
        if let year = comps.year, let month = comps.month {
            let currentMonthKey = "\(year)-\(month)"
            if monthDict[currentMonthKey] == nil {
                monthDict[currentMonthKey] = [:]
            }
        }
        
        displayMonths = sortArchiveMonths(from: monthDict)
        displayPostCount = filteredPosts.count
        currentMonthIndex = 0
    }
    
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
            print("DataManager 데이터 불러오기 실패: \\(error.localizedDescription)")
            return []
        }
    }

    // 월별 아카이브에 필요한 구조로 데이터 정리
    private func processPosts(_ posts: [PostData]) -> [String: [Int: ArchiveDay]] {
        var monthDict: [String: [Int: ArchiveDay]] = [:]
        
        for postData in posts {
            let date = postData.createdAt.dateValue()
            
            let stickerType: StickerType? = {
                guard let s = postData.stickerType, s != "null" else { return nil }
                return StickerType(rawValue: s)
            }()
            
            let post = ArchivePost(
                id: postData.postId,
                createdAt: date,
                updatedAt: postData.updatedAt.dateValue(),
                authorUid: postData.authorId,
                authorName: nil,
                frontImageURL: postData.frontURL,
                backImageURL: postData.backURL,
                caption: postData.caption,
                stickerPostId: postData.stickerPostId,
                stickerType: stickerType
            )
            
            let comps = DateUtils.components(from: date)
            guard let y = comps.year, let m = comps.month, let d = comps.day else { continue }
            let monthKey = "\(y)-\(m)"
            if monthDict[monthKey] == nil { monthDict[monthKey] = [:] }
            
            if monthDict[monthKey]?[d] == nil {
                guard let thumbnail = post.thumbnailURL else { continue }
                monthDict[monthKey]?[d] = ArchiveDay(
                    id: post.id,
                    day: d,
                    thumbnailURL: thumbnail,
                    postId: post.id
                )
            }
        }
        return monthDict
    }

    // 월별 데이터 정렬
    private func sortArchiveMonths(from monthDict: [String: [Int: ArchiveDay]]) -> [ArchiveMonth] {
        let result: [ArchiveMonth] = monthDict.compactMap { key, dayMap in
            let parts = key.split(separator: "-")
            guard let y = Int(parts[0]), let m = Int(parts[1]) else { return nil }
            let days = dayMap.keys.sorted().reversed().compactMap { dayMap[$0] }
            return ArchiveMonth(id: key, year: y, month: m, days: days)
        }
            .sorted {
                if $0.year == $1.year { return $0.month > $1.month }
                return $0.year > $1.year
            }
        return result
    }
}
