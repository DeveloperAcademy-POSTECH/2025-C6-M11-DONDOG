//
//  PostViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/4/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class PostViewModel: ObservableObject {
    let postId: String
    let roomId: String
    
    private let db = Firestore.firestore()
    private let postService = PostService.shared
    private var postRef: DocumentReference
    private var commentRef: DocumentReference

    @Published var uid: String = ""
    @Published var currentUser: String = ""
    @Published var authorName: String = ""
    @Published var createdAt: Date = Date()
    @Published var caption: String?
    @Published var stickerImage: UIImage = UIImage()
    @Published var comments: [Comment] = []
    @Published var showDeleteConfirmAlert = false
    @Published var showUnauthorizedAlert = false
    @Published var commentToDelete: Comment? = nil

    private var stickerURL: URL?
    @Published var frontURL: URL?
    @Published var backURL: URL?
    
    init(postId: String, roomId: String) {
        self.postId = postId
        self.roomId = roomId
        let roomRef = db.collection("Rooms").document(roomId)
        self.postRef = roomRef.collection("posts").document(postId)
        self.commentRef = roomRef.collection("comments").document(postId)
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

        let stickerImage = await sticker

        await MainActor.run {
            if let stickerImage = stickerImage { self.stickerImage = stickerImage }
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
        let tempComment = Comment(
            uid: currentUser,
            text: text,
            createdAt: Date()
        )

        await MainActor.run {
            comments.append(tempComment)
        }

        Task {
            do {
                let commentData: [String: Any] = [
                    "uid": currentUser,
                    "text": text,
                    "createdAt": Timestamp(date: Date())
                ]
                try await commentRef.collection("comments").addDocument(data: commentData)

                await fetchComments()
            } catch {
                print("댓글 업로드 실패: \(error.localizedDescription)")

                await MainActor.run {
                    comments.removeAll { $0.id == tempComment.id }
                }
            }
        }
    }
    
    func fetchComments() async {
        do {
            let snapshot = try await self.commentRef.collection("comments").getDocuments()
            let fetchedComments = snapshot.documents.compactMap { Comment(doc: $0) }
            await MainActor.run {
                self.comments = fetchedComments.sorted { $0.createdAt < $1.createdAt }
            }
        } catch {
            print("댓글 로드 실패:", error.localizedDescription)
        }
    }
    
    func deleteComment(of comment: Comment) {
        comments.removeAll { $0.id == comment.id }

        Task {
            do {
                try await postService.deleteComment(comment, postId: self.postId, in: self.roomId)
                await fetchComments()
            } catch {
                print("댓글 삭제 실패: ", error.localizedDescription)
                await MainActor.run {
                    comments.append(comment)
                }
            }
        }
    }
    
    func deletePost() async throws {
        let userId = Auth.auth().currentUser!.uid
        try await postService.deletePost(postId: self.postId, in: self.roomId, by: userId)
    }
    
    func handleDeleteRequest() {
        if uid == currentUser {
            showDeleteConfirmAlert = true
        } else {
            showUnauthorizedAlert = true
        }
    }
}
