//
//  PostViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/4/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class PostViewModel: ObservableObject {
    let postId: String
    let roomId: String
    
    private let db = Firestore.firestore()
    private var postRef: DocumentReference

    private var uid: String = ""
    @Published var authorName: String = ""
    @Published var createdAt: Date = Date()
    @Published var frontImage: UIImage = UIImage()
    @Published var backImage: UIImage = UIImage()
    @Published var caption: String?
    @Published var stickerImage: UIImage = UIImage()
    @Published var comments: [Comment] = []

    private var stickerURL: URL?
    private var frontURL: URL?
    private var backURL: URL?

    init(postId: String, roomId: String) {
        self.postId = postId
        self.roomId = roomId
        self.postRef = db.collection("Rooms").document(roomId)
                         .collection("posts").document(postId)

        Task {
            await self.fetchPostData()
            await self.fetchComments()
        }
    }

    func fetchPostData() async {
        guard !roomId.isEmpty, !postId.isEmpty else { return }
        
        do {
            let postSnapshot = try await postRef.getDocument()
            
            guard let data = postSnapshot.data() else { return }
            self.uid = data["uid"] as? String ?? ""
            self.caption = data["caption"] as? String
            self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            
            if let urlString = data["frontImageURL"] as? String {
                self.frontURL = URL(string: urlString)
            }
            
            if let urlString = data["backImageURL"] as? String {
                self.backURL = URL(string: urlString)
            }
            
            if !self.uid.isEmpty {
                let userRef = db.collection("Users").document(self.uid)
                let userSnapshot = try await userRef.getDocument()
                if let userData = userSnapshot.data() {
                    self.authorName = userData["name"] as? String ?? "Unknown"
                    if let urlString = userData["recentSticker"] as? String {
                        self.stickerURL = URL(string: urlString)
                    }
                }
            }
            
            await loadImages()
        } catch {
            print("Firestore 데이터 로드 실패:", error.localizedDescription)
        }
    }

    private func loadImages() async {
        async let sticker = stickerURL != nil ? loadImage(from: stickerURL!) : nil
        async let front = frontURL != nil ? loadImage(from: frontURL!) : nil
        async let back = backURL != nil ? loadImage(from: backURL!) : nil

        let (stickerImage, frontImage, backImage) = await (sticker, front, back)

        await MainActor.run {
            if let stickerImage = stickerImage { self.stickerImage = stickerImage }
            if let frontImage = frontImage { self.frontImage = frontImage }
            if let backImage = backImage { self.backImage = backImage }
        }
    }

    func loadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("이미지 로드 실패:", error.localizedDescription)
            return nil
        }
    }
    
    func saveComment(of text: String) async {
        guard let currentUser = Auth.auth().currentUser else {
            print("사용자 인증 정보 없음")
            return
        }
        
        do {
            let userRef = db.collection("Users").document(currentUser.uid)
            let userSnapshot = try await userRef.getDocument()
            let authorName = userSnapshot.data()?["name"] as? String ?? "Unknown"

            let commentData: [String: Any] = [
                "uid": currentUser.uid,
                "author": authorName,
                "content": text,
                "timestamp": Timestamp(date: Date())
            ]

            
            try await postRef.collection("comments").addDocument(data: commentData)

            await fetchComments()
        } catch {
            print("댓글 업로드 실패: \(error.localizedDescription)")
        }
    }
    
    func fetchComments() async {
        let commentsRef = postRef.collection("comments")
        do {
            let snapshot = try await commentsRef.getDocuments()
            let fetchedComments = snapshot.documents.compactMap { doc -> Comment? in
                return Comment(dict: doc.data())
            }
            await MainActor.run {
                self.comments = fetchedComments.sorted { $0.timestamp < $1.timestamp }
            }
        } catch {
            print("댓글 로드 실패:", error.localizedDescription)
        }
    }
}


//import Combine
//import SwiftUI
//import Vision
//import CoreImage.CIFilterBuiltins
//
//final class PostViewModel: ObservableObject {
//    // TODO: print문 로그로 변경, 예외 처리
//    @Published var image: UIImage? = nil
//    private let ciContext = CIContext()
//
//    private func getImage() {
//        image = UIImage(named: "StickerImage")
//    }
//
//    private func renderToCIImage(image: UIImage) -> CIImage? {
//        guard let ciImage = CIImage(image: image) else {
//            print("Failed to create CIImage")
//            return nil
//        }
//        return ciImage
//    }
//
//    private func makeMask(image: CIImage) -> CIImage? {
//            let request = VNGeneratePersonSegmentationRequest()
//            request.qualityLevel = .balanced
//            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
//
//            let handler = VNImageRequestHandler(ciImage: image)
//            do {
//                try handler.perform([request])
//            } catch {
//                print("Vision request failed: \(error)")
//                return nil
//            }
//
//            guard let maskBuffer = request.results?.first?.pixelBuffer else {
//                print("No mask results found")
//                return nil
//            }
//
//        let mask = CIImage(cvPixelBuffer: maskBuffer)
//        let resizedMask = mask.transformed(by: CGAffineTransform(scaleX: image.extent.width / mask.extent.width,
//                                                                 y: image.extent.height / mask.extent.height))
//        return resizedMask.cropped(to: image.extent)
//
//        }
//
//
//    private func applyingMask(mask: CIImage, to image: CIImage) -> CIImage? {
//        let filter = CIFilter.blendWithMask()
//        filter.inputImage = image
//        filter.maskImage = mask
//        filter.backgroundImage = CIImage.empty()
//        return filter.outputImage
//    }
//
//    private func renderToUIImage(ciImage: CIImage, original: UIImage) -> UIImage? {
//        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
//            print("Failed to render CGImage")
//            return nil
//        }
//        return UIImage(cgImage: cgImage, scale: original.scale, orientation: original.imageOrientation)
//    }
//
//
//    func makeSticker() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.getImage()
//
//            guard let image = self.image,
//                  let originalCIImage = self.renderToCIImage(image: image),
//                  let mask = self.makeMask(image: originalCIImage),
//                  let clippedCIImage = self.applyingMask(mask: mask, to: originalCIImage),
//                  let finalImage = self.renderToUIImage(ciImage: clippedCIImage, original: image) else {
//                print("Image processing failed")
//                return
//            }
//
//            DispatchQueue.main.async {
//                self.image = finalImage
//            }
//        }
//    }
//
//}
