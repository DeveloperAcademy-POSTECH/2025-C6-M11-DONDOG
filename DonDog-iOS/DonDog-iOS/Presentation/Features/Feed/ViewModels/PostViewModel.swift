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
import Kingfisher

final class PostViewModel: ObservableObject {
    let postId: String
    let roomId: String
    
    private let db = Firestore.firestore()
    private let postService = PostService.shared
    private var postRef: DocumentReference?
    private var commentRef: DocumentReference?
    private var imageUtils = ImageUtils()
    private var stickerPostId: String = ""

    @Published var uid: String = ""
    @Published var currentUser: String = ""
    @Published var frontURL: URL?
    @Published var backURL: URL?
    @Published var authorName: String = ""
    @Published var createdAt: Date = Date()
    @Published var caption: String?
    @Published var borderedSticker: UIImage = UIImage()
    @Published var emotion: String = ""
    @Published var comments: [Comment] = []
    
    @Published var showDeleteConfirmAlert = false
    @Published var showUnauthorizedAlert = false
    @Published var commentToDelete: Comment? = nil
    
    init(postId: String, roomId: String) {
        self.postId = postId
        self.roomId = roomId
        self.currentUser = Auth.auth().currentUser?.uid ?? ""
        
        // 방어: 빈 경로로 DocumentReference를 만들지 않도록 지연 생성
        if !roomId.isEmpty, !postId.isEmpty {
            let roomRef = db.collection("Rooms").document(roomId)
            self.postRef = roomRef.collection("posts").document(postId)
            self.commentRef = roomRef.collection("comments").document(postId)
        } else {
            assertionFailure("PostViewModel init received empty roomId or postId")
        }

        Task {
            await self.fetchPostData()
            await self.fetchComments()
        }
    }
    
    func getStickerData() {
        // stickerPostId가 비어 있으면 아무 것도 하지 않음 (크래시 방지)
        guard !roomId.isEmpty, !stickerPostId.isEmpty else { return }
        
        let stickerPostRef = db.collection("Rooms").document(roomId).collection("posts").document(self.stickerPostId)
        stickerPostRef.getDocument(source: .default) { [weak self] stickerSnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("스티커용 post 조회 실패:", error.localizedDescription)
                return
            }
            guard
                let stickerData = stickerSnapshot?.data(),
                let imageUrlString = stickerData["frontImageURL"] as? String
            else {
                print("스티커 frontImageURL 없음")
                return
            }
            
            let postRef = self.db.collection("Rooms").document(self.roomId).collection("posts").document(self.postId)
            postRef.getDocument(source: .default) { postSnapshot, postError in
                if let postError = postError {
                    print("현재 postId \(self.postId) 조회 실패:", postError.localizedDescription)
                    return
                }
                guard
                    let postData = postSnapshot?.data(),
                    let emotion = postData["stickerType"] as? String
                else {
                    print("현재 postId \(self.postId)에 유효한 stickerType 없음")
                    return
                }
                
                guard let url = URL(string: imageUrlString) else {
                    print("스티커 이미지 URL 생성 실패")
                    return
                }
                
                // KF 캐시 우선 조회 후 네트워크 폴백
                KingfisherManager.shared.retrieveImage(with: url) { result in
                    switch result {
                    case .success(let value):
                        let image = value.image
                        
                        // @Sendable 클로저 내부에서 self 캡처를 줄이기 위해 미리 색상을 계산
                        let borderColor = self.borderColor(for: emotion)
                        let utils = self.imageUtils
                        
                        DispatchQueue.global(qos: .userInitiated).async {
                            guard let stickerOnly = utils.makeSticker(with: image) else {
                                print("스티커 생성 실패")
                                DispatchQueue.main.async { self.borderedSticker = UIImage() }
                                return
                            }
                            
                            let resultImage: UIImage
                            if let bordered = stickerOnly.addBorder(thickness: 50, color: borderColor) {
                                resultImage = bordered
                            } else {
                                print("테두리 추가 실패, 기본 스티커 반환")
                                resultImage = stickerOnly
                            }
                            
                            DispatchQueue.main.async {
                                self.borderedSticker = resultImage
                                self.emotion = emotion
                            }
                        }
                    case .failure(let error):
                        print("KF 스티커 이미지 조회 실패:", error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func borderColor(for emotion: String) -> UIColor {
        switch emotion {
        case "사랑해":
            return .ddFeelingPink
        case "멋지다":
            return .ddFeelingYellow
        case "뭐야?":
            return .ddFeelingGreen
        case "화나":
            return .ddFeelingOrange
        case "슬퍼":
            return .ddFeelingBlue
        default:
            return .ddGray700
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
        guard !roomId.isEmpty, !postId.isEmpty, let postRef = self.postRef else { return }
        
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
            
            self.stickerPostId = data["stickerPostId"] as? String ?? ""
            
            // stickerPostId가 있을 때만 호출
            if !self.stickerPostId.isEmpty {
                self.getStickerData()
            }
            
            await loadImages()
        } catch {
            print("Firestore 데이터 로드 실패:", error.localizedDescription)
        }
    }

    private func loadImages() async {
        await MainActor.run {
            // 이미지 관련 추가 로딩이 필요하면 여기에
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
        guard let commentRef = self.commentRef else {
            assertionFailure("commentRef is nil (invalid roomId/postId)")
            return
        }
        
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
        guard let commentRef = self.commentRef else { return }
        do {
            let snapshot = try await commentRef.collection("comments").getDocuments()
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

