//
//  PhotoSaveService.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/6/25.
//

import Combine
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

final class PhotoSaveService: ObservableObject {
    static let shared = PhotoSaveService()
    private let dataManager = FirebaseDataManager.shared
    private init() {}
    
    // MARK: - : Room의 posts에 저장
    func uploadImagesToRoomPosts(frontImage: UIImage, backImage: UIImage, caption: String, completion: @escaping (Result<PostData, Error>) -> Void) {
        Task {
            do {
                // 1) RoomId 확보
                let roomId = try await dataManager.getCurrentUserRoomId()
                print("사용자 roomId: \(roomId)")

                // 2) 사용자 UID 확보
                guard let uid = dataManager.getCurrentUserId() else {
                    throw DataManagerError.authenticationRequired
                }

                // 3) 스토리지 업로드
                let postId = UUID().uuidString
                print("전면/후면 이미지 업로드 시작 - Post ID: \(postId)")

                async let frontURLTask = dataManager.uploadImage(
                    image: frontImage,
                    path: "rooms/\(roomId)/posts/\(postId)/front.jpg"
                )
                async let backURLTask = dataManager.uploadImage(
                    image: backImage,
                    path: "rooms/\(roomId)/posts/\(postId)/back.jpg"
                )

                let (frontURL, backURL) = try await (frontURLTask, backURLTask)
                print("전면/후면 이미지 업로드 모두 완료")

                // 4) Firestore 저장을 위한 모델 구성
                let postData = PostData(
                    postId: postId,
                    uid: uid,
                    frontImageURL: frontURL,
                    backImageURL: backURL,
                    caption: caption,
                    stickerPostId: "",
                    stickerType: nil
                )

                // 5) Firestore 문서 쓰기 (Rooms/{roomId}/posts/{postId})
                var dict = try Firestore.Encoder().encode(postData)
                dict["uid"] = postData.uid
                dict["createdAt"] = FieldValue.serverTimestamp()
                dict["updatedAt"] = FieldValue.serverTimestamp()

                try await dataManager.create(
                    path: "Rooms/\(roomId)/posts/\(postId)",
                    data: dict
                )

                // 6) 사용자 문서 갱신 (Users/{uid})
                try await dataManager.update(
                    path: "Users/\(uid)",
                    data: [
                        "recentPostId": postId,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                )

                // 7) 완료 콜백
                await MainActor.run { completion(.success(postData)) }
            } catch {
                print("이미지 업로드/저장 중 오류 발생: \(error.localizedDescription)")
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func fetchTodayRoomPosts(roomId: String, completion: @escaping (Result<[PostData], Error>) -> Void) {
        print("오늘 찍은 Room posts 조회 시작: \(roomId)")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayTimestamp = Timestamp(date: today)
        
        print("오늘 날짜: \(today)")
        
        Task {
            do {
                let posts: [PostData] = try await dataManager.fetchWhere(
                    path: "Rooms/\(roomId)/posts",
                    field: "createdAt",
                    isGreaterThanOrEqualTo: todayTimestamp,
                    orderBy: "createdAt",
                    descending: true
                )
                
                completion(.success(posts))
            } catch {
                print("❌ 오늘 posts 조회 실패: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
