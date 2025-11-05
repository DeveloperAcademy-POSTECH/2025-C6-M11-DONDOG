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
    @Published var allPosts: [PostData] = []
    @Published var totalPostCount: Int = 0
    @Published var isLoading = false
    
    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    // 날짜 포매팅
    private func getDate(from month: ArchiveMonth, day: ArchiveDay) -> Date? {
        return DateUtils.date(fromYear: month.year, month: month.month, day: day.day)
    }
    
    // 날짜 설정
    func dayKey(from date: Date) -> String {
        let startOfDay = DateUtils.startOfDay(for: date)
        return DateUtils.string(from: startOfDay, format: .dayKey)
    }
    
    // 일자별 기록으로 이동
    func moveDailyArchive(month: ArchiveMonth, day: ArchiveDay) {
        guard let selectedDate = getDate(from: month, day: day) else { return }

        let startOfDay = DateUtils.startOfDay(for: selectedDate)
        let endOfDay = startOfDay.addingTimeInterval(24 * 60 * 60)

        let postsForDay = self.allPosts.filter { post in
            let postDate = post.createdAt.dateValue()
            return postDate >= startOfDay && postDate < endOfDay
        }

        DispatchQueue.main.async {
            self.coordinator?.push(
                .post(post: postsForDay.first!, postType: .archive)
            )
        }
    }
    
    // 전체 기록 가져오기
    func fetchMonthlyArchives() async {
        await MainActor.run { isLoading = true }
        
        let (monthData, totalCount, allPosts) = await fetchAllPostsAndCount()
        
        await MainActor.run {
            self.archiveMonths = monthData
            self.totalPostCount = totalCount
            self.allPosts = allPosts
            self.isLoading = false
        }
    }
    
    private func fetchAllPostsAndCount() async -> ([ArchiveMonth], Int, [PostData]) {
        guard let roomId = connectUserInfo.roomId, !roomId.isEmpty else {
            return ([], 0, [])
        }
        
        do {
            let posts: [PostData] = try await dataManager.fetchCollection(
                path: "Rooms/\(roomId)/posts",
                orderBy: "createdAt",
                descending: false
            )
            
            let monthDict = processPosts(posts)
            let archiveMonths = sortArchiveMonths(from: monthDict)
            
            return (archiveMonths, posts.count, posts)
            
        } catch {
            print("DataManager 데이터 불러오기 실패: \(error.localizedDescription)")
            return ([], 0, [])
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
