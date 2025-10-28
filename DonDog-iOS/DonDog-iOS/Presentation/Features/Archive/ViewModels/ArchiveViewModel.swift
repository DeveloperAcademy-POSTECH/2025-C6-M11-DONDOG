//
//  ArchiveViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/11/25.
//

import Combine
import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit
import SwiftUI

final class ArchiveViewModel: ObservableObject {
    let connectState = ConnectStateService.shared
    var stickerViewModel: ArchiveStickerViewModel
    private weak var coordinator: AppCoordinator?
    
    @Published var archiveMonths: [ArchiveMonth] = []
    @Published var dailyPosts: [String: [ArchivePost]] = [:]
    @Published var totalPostCount: Int = 0
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private let calendar = Calendar(identifier: .gregorian)
    private let timezone = TimeZone(identifier: "Asia/Seoul") ?? .current
    
    private lazy var dayKeyFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = calendar
        df.timeZone = timezone
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    init(stickerViewModel: ArchiveStickerViewModel) {
        self.stickerViewModel = stickerViewModel
    }
    
    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    func onAppear() {
        Task {
            await fetchMonthlyArchives()
        }
        NSLog("[ArchiveViewModel] roomId = \(connectState.roomId ?? "roomId 비어있음")")
    }
    
    func dayKey(from date: Date) -> String {
        let startOfDay = calendar.startOfDay(for: date)
        return dayKeyFormatter.string(from: startOfDay)
    }
    
    // 날짜 포매팅
    private func getDate(from month: ArchiveMonth, day: ArchiveDay) -> Date? {
        var calendar = self.calendar
        calendar.timeZone = self.timezone
        let components = DateComponents(
            year: month.year,
            month: month.month,
            day: day.day,
            hour: 0,
            minute: 0,
            second: 0
        )
        return calendar.date(from: components)
    }
    
    // 일자별 기록으로 이동
    func moveDailyArchive(month: ArchiveMonth, day: ArchiveDay) {
        guard let selectedDate = getDate(from: month, day: day) else { return }
        
        let key = dayKey(from: selectedDate)
        let initial = dailyPosts[key] ?? []
        
        coordinator?.push(
            .archiveDetail(roomId: connectState.roomId ?? "", date: selectedDate, initialPosts: initial)
        )
    }
    
    // 전체 기록 가져오기
    func fetchMonthlyArchives() async {
        await MainActor.run { isLoading = true }
        
        async let months = fetchAllPosts()
        async let count = fetchPostCount()
        let (monthData, totalCount) = await (months, count)
        
        await MainActor.run {
            self.archiveMonths = monthData
            self.totalPostCount = totalCount
            self.isLoading = false }
    }
    
    // 월/일 별로 전체 기록 가져오기 -> 일자별 기록 캐싱
    private func fetchAllPosts() async -> [ArchiveMonth] {
        do {
            let snapshot = try await db.collection("Rooms").document(connectState.roomId ?? "")
                .collection("posts")
                .order(by: "createdAt", descending: false) // 오래된 것부터
                .getDocuments(source: .server)
            
            var monthDict: [String: [Int: ArchiveDay]] = [:]
            var dayDict: [String: [ArchivePost]] = [:]
            
            // 디버깅용 날짜 포매팅
            let fmt = DateFormatter()
            fmt.calendar = calendar
            fmt.timeZone = timezone
            fmt.locale = Locale(identifier: "ko_KR")
            fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            for doc in snapshot.documents {
                let data = doc.data()
                guard let tsCreated = data["createdAt"] as? Timestamp else { continue }
                let date = tsCreated.dateValue()
                
                
                let caption = data["caption"] as? String
                let stickerPostId = data["stickerPostId"] as? String
                let stickerTypeString = (data["stickerType"] as? String)?.lowercased()
                let stickerType: StickerType? = {
                    guard let s = stickerTypeString, s != "null" else { return nil }
                    return StickerType(rawValue: s)
                }()
                
                stickerViewModel.getStickerData(stickerPostId: stickerPostId ?? "", for: doc.documentID)
                
                let post = ArchivePost(
                    id: doc.documentID,
                    createdAt: tsCreated.dateValue(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? tsCreated.dateValue(),
                    authorUid: data["uid"] as? String,
                    authorName: (data["authorName"] as? String) ?? (data["authorId"] as? String),
                    frontImageURL: (data["frontImageURL"] as? String).flatMap(URL.init(string:)),
                    backImageURL:  (data["backImageURL"]  as? String).flatMap(URL.init(string:)),
                    caption: caption,
                    stickerPostId: stickerPostId,
                    stickerType: stickerType
                )
                
                let dayKeyStr = dayKey(from: date)
                dayDict[dayKeyStr, default: []].append(post)
                
                let comps = calendar.dateComponents(in: timezone, from: date)
                guard let y = comps.year, let m = comps.month, let d = comps.day else { continue }
                let monthKey = "\(y)-\(m)"
                if monthDict[monthKey] == nil { monthDict[monthKey] = [:] }
                
                // 해당 날짜에 찍은 첫 사진을 썸네일로 채택
                if monthDict[monthKey]?[d] == nil {
                    guard let thumbnail = post.thumbnailURL else { continue }
                    
                    monthDict[monthKey]?[d] = ArchiveDay(
                        id: doc.documentID,
                        day: d,
                        thumbnailURL: thumbnail,
                        postId: doc.documentID
                    )
#if DEBUG
                    print("""
                    썸네일
                    - 날짜: \(fmt.string(from: date))) (\(y)-\(m)-\(d))
                    - id: \(doc.documentID)
                    - url: \(thumbnail.absoluteString)
                    """)
#endif
                } else {
#if DEBUG
                    print("사진들 \(fmt.string(from: date)) docId=\(doc.documentID)")
#endif
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
            return result
        } catch {
            print("Firestore 데이터 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    // 게시물 개수 조회
    private func fetchPostCount() async -> Int {
        do {
            let countQuery = db.collection("Rooms").document(connectState.roomId ?? "").collection("posts")
                .count
            
            let snapshot = try await countQuery.getAggregation(source: .server)
            
            return snapshot.count.intValue
        } catch {
            print("Count 쿼리 실패: \(error.localizedDescription)")
            return 0
        }
    }
}
