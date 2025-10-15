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

final class ArchiveViewModel: ObservableObject {
    @Published var archiveMonths: [ArchiveMonth] = []
    @Published var totalPostCount: Int = 0
    @Published var isLoading = false
    @Published var myNickname: String = ""
    @Published var partnerNickname: String = ""
    let roomId: String
    private let db = Firestore.firestore()
    private let calendar = Calendar(identifier: .gregorian)
    private let timezone = TimeZone(identifier: "Asia/Seoul") ?? .current
    
    init(roomId: String) {
        self.roomId = roomId
        Task {
            await fetchMonthlyArchives()
            await fetchPartnerNicknames()
        }
    }
    
    // 전체 기록 가져오기
    func fetchMonthlyArchives() async {
        await MainActor.run { isLoading = true }
        
        async let posts = fetchAllPosts()
        async let count = fetchPostCount()
        
        let (monthData, totalCount) = await (posts, count)
        await MainActor.run {
            self.archiveMonths = monthData
            self.totalPostCount = totalCount
            self.isLoading = false }
    }
    
    @MainActor func fetchPartnerNicknames() async {
        guard let result = await fetchPartnerNickname() else { return }
        self.myNickname = result.myNickname
        self.partnerNickname = result.partnerNickname
    }
    
    // 월/일 별로 전체 기록 가져오기
    private func fetchAllPosts() async -> [ArchiveMonth] {
        do {
            let snapshot = try await db.collection("Rooms")
                .document(roomId)
                .collection("posts")
                .order(by: "createdAt", descending: false) // 오래된 것부터
                .getDocuments()
            
            var monthDict: [String: [Int: ArchiveDay]] = [:]
            
            // 디버깅용 날짜 포매팅
            let fmt = DateFormatter()
            fmt.calendar = calendar
            fmt.timeZone = timezone
            fmt.locale = Locale(identifier: "ko_KR")
            fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            for doc in snapshot.documents {
                let data = doc.data()
                guard let ts = data["createdAt"] as? Timestamp else { continue }
                
                let urlString = (data["frontImageURL"] as? String)
                ?? (data["backImageURL"] as? String) // front 없으면 back 폴백
                guard let urlString, let url = URL(string: urlString) else { continue }
                
                let date = ts.dateValue()
                let comps = calendar.dateComponents(in: timezone, from: date)
                guard let y = comps.year, let m = comps.month, let d = comps.day else { continue }
                
                let key = "\(y)-\(m)"
                if monthDict[key] == nil { monthDict[key] = [:] }
                
                // 해당 날짜에 찍은 첫 사진을 썸네일로 채택
                if monthDict[key]?[d] == nil {
                    monthDict[key]?[d] = ArchiveDay(
                        id: doc.documentID,
                        day: d,
                        thumbnailURL: url,
                        postId: doc.documentID
                    )
                    
#if DEBUG
                    print("""
                    썸네일
                    - 날짜: \(fmt.string(from: date)) (\(y)-\(m)-\(d))
                    - id: \(doc.documentID)
                    - url: \(url.absoluteString)
                    """)
#endif
                } else {
#if DEBUG
                    print("사진들 \(fmt.string(from: date)) docId=\(doc.documentID)")
#endif
                }
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
            let countQuery = db.collection("Rooms")
                .document(roomId) .collection("posts")
                .count
            
            let snapshot = try await countQuery.getAggregation(source: .server)
            
            return snapshot.count.intValue
        } catch {
            print("Count 쿼리 실패: \(error.localizedDescription)")
            return 0
        }
    }
    
    // 상대방 닉네임 조회
    func fetchPartnerNickname() async -> (myNickname: String, partnerNickname: String)? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        
        do {
            // 1. User 조회
            let userSnap = try await db.collection("Users").document(uid).getDocument()
            guard
                let data = userSnap.data(),
                let myNickname = data["name"] as? String,
                let roomId = data["roomId"] as? String
            else { return nil }
            
            // 2. Room 조회
            let roomSnap = try await db.collection("Rooms")
                .document(roomId)
                .getDocument()
            guard
                let roomData = roomSnap.data(),
                let participants = roomData["participants"] as? [String]
            else { return nil }
            
            // 3. 현재 uid와 다른 참여자를 상대방으로 지정
            let partnerUid = participants.first(where: { $0 != uid })
            guard
                let partnerUid = partnerUid, partnerUid != uid
            else {
                return (myNickname, "상대방")
            }
            
            // 4. 상대방 닉네임 지정
            let partnerSnap = try await db.collection("Users").document(partnerUid).getDocument()
            let partnerNickname = partnerSnap.data()?["name"] as? String ?? "상대방"
            return (myNickname, partnerNickname)
        } catch {
            print("이름 불러오기 실패:", error.localizedDescription)
            return nil
        }
    }
}
