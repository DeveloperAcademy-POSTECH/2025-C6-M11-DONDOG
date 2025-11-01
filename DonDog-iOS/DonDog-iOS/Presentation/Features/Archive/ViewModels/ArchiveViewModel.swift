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
    private let dataManager: DataManagerProtocol
    
    @Published var archiveMonths: [ArchiveMonth] = []
    @Published var dailyPosts: [String: [ArchivePost]] = [:]
    @Published var totalPostCount: Int = 0
    @Published var isLoading = false
    
    init(dataManager: DataManagerProtocol = DataManager.shared) {
        self.dataManager = dataManager
    }
    
    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    func dayKey(from date: Date) -> String {
        let startOfDay = DateUtils.startOfDay(for: date)
        return DateUtils.string(from: startOfDay, format: .dayKey)
    }
    
    // 날짜 포매팅
    private func getDate(from month: ArchiveMonth, day: ArchiveDay) -> Date? {
        return DateUtils.date(fromYear: month.year, month: month.month, day: day.day)
    }
    
    private func convertToPostData(_ archivePosts: [ArchivePost]) -> [PostData] {
        return archivePosts.map { archivePost in
            return PostData(
                postId: archivePost.id,
                authorId: archivePost.authorUid ?? "",
                frontImageURL: archivePost.frontImageURL?.absoluteString ?? "",
                backImageURL: archivePost.backImageURL?.absoluteString ?? "",
                caption: archivePost.caption ?? "",
                createdAt: Timestamp(date: archivePost.createdAt),
                stickerPostId: archivePost.stickerPostId ?? "",
                stickerType: archivePost.stickerType?.rawValue
            )
        }
    }
    
    // 일자별 기록으로 이동
    func moveDailyArchive(month: ArchiveMonth, day: ArchiveDay) {
        guard let selectedDate = getDate(from: month, day: day) else { return }
        
        let key = dayKey(from: selectedDate)
        let initial = dailyPosts[key] ?? []
        let posts = convertToPostData(initial)
        
        DispatchQueue.main.async {
            self.coordinator?.push(
                .postDetail(posts: posts, postType: .archive)
            )
        }
    }
    
    // 전체 기록 가져오기
    func fetchMonthlyArchives() async {
        await MainActor.run { isLoading = true }
        
        let (monthData, totalCount) = await fetchAllPostsAndCount()
        
        await MainActor.run {
            self.archiveMonths = monthData
            self.totalPostCount = totalCount
            self.isLoading = false
        }
    }
    
    // 월/일 별로 전체 기록 가져오기
    private func fetchAllPostsAndCount() async -> ([ArchiveMonth], Int) {
        guard let roomId = connectUserInfo.roomId, !roomId.isEmpty else {
            return ([], 0)
        }
        
        do {
            let posts: [PostData] = try await dataManager.fetchCollection(
                path: "Rooms/\(roomId)/posts",
                orderBy: "createdAt",
                descending: false
            )
            
            var monthDict: [String: [Int: ArchiveDay]] = [:]
            var dayDict: [String: [ArchivePost]] = [:]
            
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
                
                let dayKeyStr = dayKey(from: date)
                dayDict[dayKeyStr, default: []].append(post)
                
                let comps = DateUtils.components(from: date)
                guard let y = comps.year, let m = comps.month, let d = comps.day else { continue }
                let monthKey = "\(y)-\(m)"
                if monthDict[monthKey] == nil { monthDict[monthKey] = [:] }
                
                // 해당 날짜에 찍은 첫 사진을 썸네일로 채택
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
            
            // 일자별 캐시 정렬
            for (k, arr) in dayDict {
                dayDict[k] = arr.sorted { $0.createdAt < $1.createdAt }
            }
            
            await MainActor.run {
                self.dailyPosts = dayDict
            }
            
            let result: [ArchiveMonth] = monthDict.compactMap { key, dayMap in
                let parts = key.split(separator: "-")
                guard let y = Int(parts[0]), let m = Int(parts[1]) else { return nil }
                let days = dayMap.keys.sorted().reversed().compactMap { dayMap[$0] } // 일 내림차순
                return ArchiveMonth(id: key, year: y, month: m, days: days)
            }
                .sorted {
                    if $0.year == $1.year { return $0.month > $1.month } // 최신 달이 위로
                    return $0.year > $1.year
                }
            return (result, posts.count)
        } catch {
            print("Firestore 데이터 불러오기 실패: \(error.localizedDescription)")
            return ([], 0)
        }
    }
}
