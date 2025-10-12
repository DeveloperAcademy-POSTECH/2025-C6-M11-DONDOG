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

struct ArchiveMonth: Identifiable, Hashable {
    let id: String
    let year: Int
    let month: Int
    var days: [ArchiveDay]
}

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
            await loadMonthlyArchives()
            await loadPartnerNicknames()
        }
    }
    
    // 전체 기록 가져오기
    func loadMonthlyArchives() async {
        await MainActor.run { isLoading = true }
        
        async let posts = fetchAllPosts()
        async let count = fetchPostCount()
        
        let (monthData, totalCount) = await (posts, count)
        await MainActor.run {
            self.archiveMonths = monthData
            self.totalPostCount = totalCount
            self.isLoading = false }
    }
    
    @MainActor func loadPartnerNicknames() async {
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
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var monthDict: [String: [ArchiveDay]] = [:]
            
            for doc in snapshot.documents {
                let data = doc.data()
                guard
                    let timeStamp = data["createdAt"] as? Timestamp,
                    let frontURLStr = data["frontImageURL"] as? String,
                    let frontURL = URL(string: frontURLStr)
                else { continue }
                
                let date = timeStamp.dateValue()
                let comps = calendar.dateComponents(in: timezone, from: date)
                
                guard
                    let y = comps.year,
                    let m = comps.month,
                    let d = comps.day
                else { continue }
                
                let key = "\(y)-\(m)"
                let day = ArchiveDay(id: doc.documentID, day: d, thumbnailURL: frontURL, postId: doc.documentID)
                monthDict[key, default: []].append(day)
            }
            
            let months = monthDict.compactMap { key, days -> ArchiveMonth? in
                guard !days.isEmpty else { return nil }
                let comps = key.split(separator: "-")
                guard let y = Int(comps[0]), let m = Int(comps[1]) else { return nil }
                return ArchiveMonth(id: key, year: y, month: m, days: days.sorted { $0.day < $1.day })
            }
                .sorted {
                    if $0.year == $1.year {
                        return $0.month > $1.month
                    } else {
                        return $0.year > $1.year
                    }
                }
            
            return months
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
            
            // 3. 현재 닉네임과 다른 참여자를 상대방으로 지정
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
