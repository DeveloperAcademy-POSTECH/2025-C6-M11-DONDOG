//
//  CaptionViewModel.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/9/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

protocol CaptionViewModelDelegate: AnyObject {
    func didUploadPost()
    func didStartUploading()
}

final class CaptionViewModel: ObservableObject {
    @Published var caption: String = ""
    @Published var isUploading: Bool = false
    @Published var currentIndex: Int = 0
    
    let connectUserInfo = UserPairingStore.shared
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
                guard let roomId = connectUserInfo.roomId else { return }
                guard let myUid = connectUserInfo.myUid else { return }

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

                let postData = PostData(postId: postId, authorId: myUid, frontImageURL: frontURL, backImageURL: backURL, caption: captionSnapshot, stickerPostId: "", stickerType: nil)

                var dict = try Firestore.Encoder().encode(postData)
                dict["authorId"] = postData.authorId
                dict["createdAt"] = FieldValue.serverTimestamp()
                dict["updatedAt"] = FieldValue.serverTimestamp()

                try await dataManager.create(path: "Rooms/\(roomId)/posts/\(postId)", data: dict)

                try await dataManager.update(path: "Users/\(myUid)", data: ["recentPostId": postId, "lastUploadedAt": FieldValue.serverTimestamp()])

                await MainActor.run {
                    connectUserInfo.lastUploadedAt = Date()
                    self.isUploading = false
                    print("[CaptionViewModel.uploadPost] 업로드 성공: \(postData.authorId)")
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
