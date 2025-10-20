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
    @Published var dailyPosts: [String: [ArchivePost]] = [:]
    @Published var totalPostCount: Int = 0
    @Published var isLoading = false
    @Published var myNickname: String = ""
    @Published var partnerNickname: String = ""
    
    @Published var borderedStickers: [String: UIImage] = [:]
    @Published var emotions: [String: String] = [:]
    private let imageUtils = ImageUtils()
    private var mask: UIImage?
    @Published var sticker: UIImage?
    @Published var emotion: String = "null"
    
    let roomId: String
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

    func dayKey(from date: Date) -> String {
        let startOfDay = calendar.startOfDay(for: date)
        return dayKeyFormatter.string(from: startOfDay)
    }

    
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
        
        async let months = fetchAllPosts()
        async let count = fetchPostCount()
        let (monthData, totalCount) = await (months, count)
        
        await MainActor.run {
            self.archiveMonths = monthData
            self.totalPostCount = totalCount
            self.isLoading = false }
    }

    func fetchPartnerNicknames() async {
        guard let result = await fetchPartnerNickname() else { return }
        self.myNickname = result.myNickname
        self.partnerNickname = result.partnerNickname
    }
    
    // 월/일 별로 전체 기록 가져오기 -> 일자별 기록 캐싱
    private func fetchAllPosts() async -> [ArchiveMonth] {
        do {
            let snapshot = try await db.collection("Rooms")
                .document(roomId)
                .collection("posts")
                .order(by: "createdAt", descending: false) // 오래된 것부터
                .getDocuments()
            
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
                
                if let sId = stickerPostId {
                    let trimmed = sId.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty, trimmed.lowercased() != "null" {
                        self.getStickerData(stickerPostId: trimmed, for: doc.documentID)
                    }
                }
                
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
    
    func getStickerData(stickerPostId: String, for postId: String) {
        let trimmed = stickerPostId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.lowercased() != "null" else { return }

        let stickerPostRef = db.collection("Rooms").document(roomId).collection("posts").document(trimmed)
        stickerPostRef.getDocument { [weak self] stickerSnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("스티커용 post 조회 실패:", error.localizedDescription)
                return
            }
            guard
                let stickerData = stickerSnapshot?.data(),
                let imageUrlString = stickerData["frontImageURL"] as? String
            else {
                print("스티커 frontImageURL 없음 for stickerPostId \(trimmed)")
                return
            }

            let postRef = self.db.collection("Rooms").document(self.roomId).collection("posts").document(postId)
            postRef.getDocument { postSnapshot, postError in
                if let postError = postError {
                    print("현재 postId \(postId) 조회 실패:", postError.localizedDescription)
                    return
                }
                guard
                    let postData = postSnapshot?.data(),
                    let emotion = postData["stickerType"] as? String, !emotion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, emotion.lowercased() != "null"
                else {
                    print("현재 postId \(postId)에 유효한 stickerType 없음")
                    return
                }

                PhotoSaveService.shared.downloadImage(from: imageUrlString) { result in
                    switch result {
                    case .success(let image):
                        DispatchQueue.global(qos: .userInitiated).async {
                            guard let stickerOnly = self.imageUtils.makeSticker(with: image) else {
                                print("스티커 생성 실패")
                                return
                            }
                            let borderedSticker = stickerOnly.addBorder(
                                thickness: 50,
                                color: self.borderColor(for: emotion)
                            )
                            DispatchQueue.main.async {
                                self.borderedStickers[postId] = borderedSticker
                                self.emotions[postId] = emotion
                            }
                        }
                    case .failure(let error):
                        print("스티커 이미지 다운로드 실패:", error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func makeStickerAndBordered(from image: UIImage) {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                let maskImage = self.imageUtils.makeMask(from: image)
                
                guard let stickerOnly = self.imageUtils.makeSticker(with: image) else {
                    print("스티커 생성 실패")
                    return
                }
                
                DispatchQueue.main.async {
                    self.mask = maskImage
                    self.sticker = stickerOnly
                }
            }
        }
    
    private func borderColor(for emotion: String) -> UIColor {
        switch emotion {
        case "사랑해":
            return .ddFeelingPink
        case "멋지다":
            return .ddFeelingYellow
        case "뭐야?":
            return .ddFeelingGreen
        case "화나":
            return .ddFeelingOrange
        case "슬퍼":
            return .ddFeelingBlue
        default:
            return .ddGray700
        }
    }
    
    // 게시물 개수 조회
    private func fetchPostCount() async -> Int {
        do {
            let countQuery = db.collection("Rooms")
                .document(roomId).collection("posts")
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

