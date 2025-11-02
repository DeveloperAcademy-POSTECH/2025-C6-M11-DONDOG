//
//  CaptionViewModel.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/9/25.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

protocol CaptionViewModelDelegate: AnyObject {
    func didUploadPost()
    func didStartUploading()
}

final class CaptionViewModel: ObservableObject {
    @Published var caption: String = ""
    @Published var isUploading: Bool = false
    
    weak var delegate: CaptionViewModelDelegate?
    private let dataManager: DataManagerProtocol = DataManager.shared
    
    var frontImage: UIImage?
    var backImage: UIImage?
    
    init(frontImage: UIImage?, backImage: UIImage?) {
        self.frontImage = frontImage
        self.backImage = backImage
    }
    
    func uploadPost() {
        guard let frontImage = frontImage, let backImage = backImage else {
            print("❌ 전면 또는 후면 이미지가 없습니다")
            return
        }
        
        delegate?.didStartUploading()
        
        Task {
            let captionSnapshot = await MainActor.run { self.caption }
            
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
                    authorId: uid,
                    frontImageURL: frontURL,
                    backImageURL: backURL,
                    caption: captionSnapshot,
                    stickerPostId: "",
                    stickerType: nil
                )

                // 5) Firestore 문서 쓰기 (Rooms/{roomId}/posts/{postId})
                var dict = try Firestore.Encoder().encode(postData)
                dict["authorId"] = postData.authorId
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
                await MainActor.run {
                    self.isUploading = false
                    print("✅ 업로드 성공: \(postData.authorId)")
                    print("📝 캡션: \(postData.caption)")
                    self.delegate?.didUploadPost()
                }
            } catch {
                await MainActor.run {
                    self.isUploading = false
                    print("❌ 업로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
}
