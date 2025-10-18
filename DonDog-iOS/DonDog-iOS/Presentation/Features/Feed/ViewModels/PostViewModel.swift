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
    private var commentRef: CollectionReference

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
        let roomRef = db.collection("Rooms").document(roomId)
        self.postRef = roomRef.collection("posts").document(postId)
        self.commentRef = roomRef.collection("comments").document(postId).collection("comments")
        self.currentUser = Auth.auth().currentUser?.uid ?? ""

        Task {
            await self.fetchPostData()
            await self.fetchComments()
        }
    }
    
    func fetchAuthorName(of uid: String) async -> String? {
        do {
            let snapshot = try await db.collection("Users").document(uid).getDocument()
            if let data = snapshot.data(),
               let name = data["name"] as? String {
                return name
            } else {
                return nil
            }
        } catch {
            print("작성자 이름 불러오기 실패: ", error.localizedDescription)
            return nil
        }
    }

    func fetchPostData() async {
        guard !roomId.isEmpty, !postId.isEmpty else { return }
        
        do {
            let postSnapshot = try await postRef.getDocument()
            
            guard let data = postSnapshot.data() else { return }
            self.uid = data["uid"] as? String ?? ""
            self.authorName = await self.fetchAuthorName(of: uid) ?? "익명"
            self.caption = data["caption"] as? String
            self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            
            if let urlString = data["frontImageURL"] as? String {
                self.frontURL = URL(string: urlString)
            }
            
            if let urlString = data["backImageURL"] as? String {
                self.backURL = URL(string: urlString)
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
            let commentData: [String: Any] = [
                "uid": currentUser,
                "text": text,
                "createdAt": Timestamp(date: Date())
            ]
            
            try await commentRef.addDocument(data: commentData)

            await fetchComments()
        } catch {
            print("댓글 업로드 실패: \(error.localizedDescription)")
        }
    }
    
    func fetchComments() async {
        do {
            let snapshot = try await self.commentRef.getDocuments()
            let fetchedComments = snapshot.documents.compactMap { Comment(doc: $0) }
            await MainActor.run {
                self.comments = fetchedComments.sorted { $0.createdAt < $1.createdAt }
            }
        } catch {
            print("댓글 로드 실패:", error.localizedDescription)
        }
    }
    
    func deleteComment(of comment: Comment) async {
        do {
            try await commentRef.document(comment.id).delete()
            await fetchComments()
        } catch {
            print("댓글 삭제 실패: ", error.localizedDescription)
        }
    }
}
