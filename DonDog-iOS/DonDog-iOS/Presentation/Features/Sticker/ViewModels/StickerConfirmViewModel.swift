//
//  StickerConfirmViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/4/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

final class StickerConfirmViewModel: ObservableObject {
    @Published var isUploading: Bool = false
    @Published var uploadError: String?
    let image: UIImage?
    let onDone: (UIImage) -> Void
    private var currentTags: [String] { StickerEmotionTagManager.shared.emotionTags }
    
    init(image: UIImage?, onDone: @escaping (UIImage) -> Void) {
        self.image = image
        self.onDone = onDone
    }
    
    func uploadSticker() {
        guard !isUploading else { return }
        guard let original = image else { return }
        let stickerID = UUID().uuidString
        let selectedTags = Array(currentTags.prefix(3))

        isUploading = true
        uploadError = nil

        Task {
            do {
                // 1) Storage 업로드
                let downloadURLString = try await DataManager.shared.uploadImage(
                    image: original,
                    path: "stickers/\(stickerID).jpg"
                )
                guard let url = URL(string: downloadURLString) else {
                    throw DataManagerError.invalidPath
                }

                // 2) database 문서 생성
                let uid = Auth.auth().currentUser?.uid ?? "anonymous"
                let data: [String: Any] = [
                    "uid": uid,
                    "url": url.absoluteString,
                    "emotionTags": selectedTags
                ]
                _ = try await DataManager.shared.createWithAutoId(path: "Stickers", data: data)

                await MainActor.run {
                    self.isUploading = false
                    StickerEmotionTagManager.shared.emotionTags = []
                    self.onDone(original)
                }
            } catch {
                await MainActor.run {
                    self.isUploading = false
                    self.uploadError = error.localizedDescription
                }
            }
        }
    }
}
