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

    @Published var uid: String = ""
    @Published var currentUser: String = ""
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
        self.currentUser = Auth.auth().currentUser?.uid ?? ""

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
        do {
            let userRef = db.collection("Users").document(currentUser)
            let userSnapshot = try await userRef.getDocument()
            let authorName = userSnapshot.data()?["name"] as? String ?? "Unknown"

            let commentData: [String: Any] = [
                "uid": currentUser,
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
            let fetchedComments = snapshot.documents.compactMap { Comment(doc: $0) }
            await MainActor.run {
                self.comments = fetchedComments.sorted { $0.timestamp < $1.timestamp }
            }
        } catch {
            print("댓글 로드 실패:", error.localizedDescription)
        }
    }
    
    func deleteComment(of comment: Comment) {
        postRef.collection("comments").document(comment.id).delete()
    }
}
