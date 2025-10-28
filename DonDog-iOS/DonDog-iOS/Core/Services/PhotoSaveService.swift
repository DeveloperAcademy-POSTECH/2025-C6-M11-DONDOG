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
        
        getCurrentUserRoomId { [weak self] result in
            switch result {
            case .success(let roomId):
                print("사용자 roomId: \(roomId)")
                
                self?.uploadImagesAndSaveToRoom(frontImage: frontImage, backImage: backImage, caption: caption, roomId: roomId, completion: completion)
            case .failure(let error):
                print("roomId 가져오기 실패: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func getCurrentUserRoomId(completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                guard let uid = dataManager.getCurrentUserId() else {
                    completion(.failure(DataManagerError.authenticationRequired))
                    return
                }
                
                print("현재 사용자 UID: \(uid)")
                
                let user: UserData.RoomIdOnly = try await dataManager.fetch(
                    path: "Users/\(uid)"
                )
                
                if user.roomId.isEmpty {
                    print("roomId가 비어있음")
                    completion(.failure(DataManagerError.roomIdNotFound))
                    return
                }
                
                print("roomId 가져오기 성공: \(user.roomId)")
                completion(.success(user.roomId))
            } catch DataManagerError.documentNotFound {
                print("❌ 사용자 문서가 존재하지 않음")
                completion(.failure(DataManagerError.userDocumentNotFound))
            } catch {
                print("❌ 사용자 문서 조회 실패: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    private func uploadImagesAndSaveToRoom(frontImage: UIImage, backImage: UIImage, caption: String, roomId: String, completion: @escaping (Result<PostData, Error>) -> Void) {
        Task {
            do {
                guard let uid = dataManager.getCurrentUserId() else {
                    completion(.failure(DataManagerError.authenticationRequired))
                    return
                }
                
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
                
                let postData = PostData(
                    postId: postId,
                    uid: uid,
                    frontImageURL: frontURL,
                    backImageURL: backURL,
                    caption: caption,
                    stickerPostId: "",
                    stickerType: nil
                )
                
                try await self.savePostToRoom(roomId: roomId, postId: postId, postData: postData)
                
                await MainActor.run {
                    completion(.success(postData))
                }
            } catch {
                print("이미지 업로드 중 오류 발생: \(error.localizedDescription)")
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func savePostToRoom(roomId: String, postId: String, postData: PostData) async throws {
        do {
            var dict = try Firestore.Encoder().encode(postData)
            dict["uid"] = postData.authorId
            dict["createdAt"] = FieldValue.serverTimestamp()
            dict["updatedAt"] = FieldValue.serverTimestamp()
            
            try await dataManager.create(
                path: "Rooms/\(roomId)/posts/\(postId)",
                data: dict
            )
            
            try await dataManager.update(
                path: "Users/\(postData.uid)",
                data: [
                    "recentPostId": postId,
                    "updatedAt": FieldValue.serverTimestamp()
                ]
            )
            
        } catch {
            print("Room post 저장 실패: \(error.localizedDescription)")
            throw error
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
