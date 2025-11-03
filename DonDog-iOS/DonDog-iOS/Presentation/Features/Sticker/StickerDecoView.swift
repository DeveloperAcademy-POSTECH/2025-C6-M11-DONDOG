//
//  StickerDecoView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/2/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

struct StickerDecoView: View {
    let image: UIImage?
    let onDone: (UIImage) -> Void
    private var currentTags: [String] { StickerTagManager.shared.emotionTags }
    @State private var isUploading: Bool = false
    @State private var uploadError: String?

    var body: some View {
        VStack {
            Text("만들어진 스티커를 확인해 주세요")
            
            Spacer()
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .padding(.bottom, 8)
            }
            
            Spacer()
            
            if isUploading {
                ProgressView("업로드 중…")
            }
            if let uploadError {
                Text(uploadError)
                    .foregroundColor(.red)
            }
            
            Button("확인") {
                guard !isUploading else { return }
                guard let original = image else { return }
                let resized = resizedForSticker(original, maxEdge: 140)
                let stickerID = UUID().uuidString
                let selectedTags = Array(currentTags.prefix(3))
                
                isUploading = true
                uploadError = nil
                uploadStickerImage(resized, stickerID: stickerID) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let downloadURL):
                            let uid = Auth.auth().currentUser?.uid ?? "anonymous"
                            saveStickerDocument(stickerID: stickerID, uid: uid, url: downloadURL, emotionTags: selectedTags) { saveResult in
                                DispatchQueue.main.async {
                                    switch saveResult {
                                    case .success:
                                        isUploading = false
                                        StickerTagManager.shared.emotionTags = []
                                        onDone(resized)
                                    case .failure(let err):
                                        isUploading = false
                                        uploadError = err.localizedDescription
                                    }
                                }
                            }
                        case .failure(let error):
                            isUploading = false
                            uploadError = error.localizedDescription
                        }
                    }
                }
            }
            .disabled(isUploading || image == nil)
        }
        .navigationTitle("스티커 꾸미기")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func resizedForSticker(_ image: UIImage, maxEdge: CGFloat = 140) -> UIImage {
        let originalSize = image.size
        let scale = min(maxEdge / max(originalSize.width, originalSize.height), 1)
        let newSize = CGSize(width: floor(originalSize.width * scale), height: floor(originalSize.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1 // ensure pixel sizes match points for small assets
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func uploadStickerImage(_ image: UIImage, stickerID: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "StickerUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "JPEG 변환 실패"])))
            return
        }
        let ref = Storage.storage().reference().child("stickers/\(stickerID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        ref.putData(data, metadata: metadata) { _, error in
            if let error = error { completion(.failure(error)); return }
            ref.downloadURL { url, err in
                if let err = err { completion(.failure(err)); return }
                guard let url = url else {
                    completion(.failure(NSError(domain: "StickerUpload", code: -2, userInfo: [NSLocalizedDescriptionKey: "다운로드 URL 없음"])))
                    return
                }
                completion(.success(url))
            }
        }
    }

    private func saveStickerDocument(stickerID: String, uid: String, url: URL, emotionTags: [String], completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("Stickers").document(stickerID)
        let payload: [String: Any] = [
            "uid": uid,
            "url": url.absoluteString,
            "emotionTags": emotionTags
        ]
        docRef.setData(payload) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(docRef.documentID))
            }
        }
    }
}
