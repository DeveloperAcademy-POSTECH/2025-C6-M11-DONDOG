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
    @Published var image: UIImage?
    @Published var isUploading: Bool = false
    @Published var uploadError: String?
    @Published var isSaving = false

    private var currentTags: [String] { StickerEmotionTagManager.shared.emotionTags }
    
    init(image: UIImage?) {
        self.image = image
    }
    
    func uploadSticker(onSuccess: (([String]) -> Void)? = nil) {
        guard !isUploading else { return }
        guard let original = image else { return }
        let stickerID = UUID().uuidString
        let selectedTags = Array(currentTags)

        isUploading = true
        uploadError = nil

        Task {
            do {
                // 1) Storage 업로드
                guard let pngData = original.pngData() else {
                    throw NSError(domain: "StickerUpload", code: -10, userInfo: [NSLocalizedDescriptionKey: "PNG 변환 실패"])
                }
                let ref = Storage.storage().reference().child("stickers/\(stickerID).png")
                let metadata = StorageMetadata()
                metadata.contentType = "image/png"

                let downloadURLString: String = try await withCheckedThrowingContinuation { cont in
                    ref.putData(pngData, metadata: metadata) { _, error in
                        if let error = error {
                            cont.resume(throwing: error)
                            return
                        }
                        ref.downloadURL { url, err in
                            if let err = err {
                                cont.resume(throwing: err)
                                return
                            }
                            guard let url = url else {
                                cont.resume(throwing: NSError(domain: "StickerUpload", code: -11, userInfo: [NSLocalizedDescriptionKey: "다운로드 URL 없음"]))
                                return
                            }
                            cont.resume(returning: url.absoluteString)
                        }
                    }
                }

                guard let url = URL(string: downloadURLString) else {
                    throw DataManagerError.invalidPath
                }

                // 2) database 문서 생성
                let uid = Auth.auth().currentUser?.uid ?? "anonymous"
                let data: [String: Any] = [
                    "uid": uid,
                    "url": url.absoluteString,
                    "emotionTags": selectedTags,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                _ = try await DataManager.shared.createWithAutoId(path: "Stickers", data: data)

                await MainActor.run {
                    self.isUploading = false
                    StickerEmotionTagManager.shared.emotionTags = []
                    onSuccess?(selectedTags)
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
