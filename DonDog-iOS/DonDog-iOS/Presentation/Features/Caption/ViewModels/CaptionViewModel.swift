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

enum CaptionUploadResult {
    case success
    case failure(message: String)
}

protocol CaptionViewModelDelegate: AnyObject {
    func didStartUploading(frontImage: UIImage?, backImage: UIImage?, caption: String)
    func didFinishUploading(result: CaptionUploadResult)
}

final class CaptionViewModel: ObservableObject {
    @Published var caption: String = ""
    @Published var currentIndex: Int = 0
    
    let connectUserInfo = UserPairingStore.shared
    weak var uploadStatusDelegate: CaptionViewModelDelegate?
    private let dataManager: DataManagerProtocol = DataManager.shared
    private var isUploading: Bool = false
    
    var frontImage: UIImage?
    var backImage: UIImage?
    
    init(frontImage: UIImage?, backImage: UIImage?) {
        self.frontImage = frontImage
        self.backImage = backImage
    }
    
    func uploadPost() {
        guard !isUploading else { return }
        
        guard let frontImage = frontImage, let backImage = backImage else {
            print("❌ 전면 또는 후면 이미지가 없습니다")
            return
        }
        guard let roomId = connectUserInfo.roomId else {
            uploadStatusDelegate?.didFinishUploading(result: .failure(message: "roomId를 찾을 수 없습니다"))
            return
        }
        guard let myUid = connectUserInfo.myUid else {
            uploadStatusDelegate?.didFinishUploading(result: .failure(message: "myUid를 찾을 수 없습니다"))
            return
        }
        
        isUploading = true
        let captionSnapshot = self.caption
        uploadStatusDelegate?.didStartUploading(frontImage: frontImage, backImage: backImage, caption: captionSnapshot)
        
        Task {
            defer {
                self.isUploading = false
            }
            do {
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

                let postData = PostData(postId: postId, authorId: myUid, frontImageURL: frontURL, backImageURL: backURL, caption: captionSnapshot, stickerType: nil)

                var dict = try Firestore.Encoder().encode(postData)
                dict["authorId"] = postData.authorId
                dict["createdAt"] = FieldValue.serverTimestamp()
                dict["updatedAt"] = FieldValue.serverTimestamp()

                try await dataManager.create(path: "Rooms/\(roomId)/posts/\(postId)", data: dict)

                try await dataManager.update(path: "Users/\(myUid)", data: ["recentPostId": postId, "lastUploadedAt": FieldValue.serverTimestamp()])

                connectUserInfo.lastUploadedAt = Date()
                print("[CaptionViewModel.uploadPost] 업로드 성공: \(postData.authorId)")
                self.uploadStatusDelegate?.didFinishUploading(result: .success)
            } catch {
                print("❌ 업로드 실패: \(error.localizedDescription)")
                self.uploadStatusDelegate?.didFinishUploading(result: .failure(message: error.localizedDescription))
            }
        }
    }
    
}
