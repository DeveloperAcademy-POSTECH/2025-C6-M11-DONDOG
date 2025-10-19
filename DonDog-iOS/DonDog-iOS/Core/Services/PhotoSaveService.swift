//
//  PhotoSaveService.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/6/25.
//

import Combine
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

final class PhotoSaveService: ObservableObject {
    static let shared = PhotoSaveService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    
    @Published var sticker: UIImage = UIImage()
    
    private init() {}
    
    // MARK: - : Room의 posts에 저장
    func uploadImagesToRoomPosts(frontImage: UIImage, backImage: UIImage, caption: String, completion: @escaping (Result<PostData, Error>) -> Void) {
        print("🏠 Room의 posts에 전면/후면 이미지 업로드 시작")
        
        getCurrentUserRoomId { [weak self] result in
            switch result {
            case .success(let roomId):
                print("✅ 사용자 roomId: \(roomId)")
                
                self?.uploadImagesAndSaveToRoom(frontImage: frontImage, backImage: backImage, caption: caption, roomId: roomId, completion: completion)
            case .failure(let error):
                print("❌ roomId 가져오기 실패: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func getCurrentUserRoomId(completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        let uid = currentUser.uid
        print("👤 현재 사용자 UID: \(uid)")
        
        db.collection("Users").document(uid).getDocument { document, error in
            if let error = error {
                print("❌ 사용자 문서 조회 실패: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                print("❌ 사용자 문서가 존재하지 않음")
                completion(.failure(FirebaseError.userDocumentNotFound))
                return
            }
            
            let roomId = document.get("roomId") as? String ?? ""
            if roomId.isEmpty {
                print("❌ roomId가 비어있음")
                completion(.failure(FirebaseError.roomIdNotFound))
                return
            }
            
            completion(.success(roomId))
            print("✅ 사용자 roomId: \(roomId)")
        }
    }
    
    
    private func uploadImagesAndSaveToRoom(frontImage: UIImage, backImage: UIImage, caption: String, roomId: String, completion: @escaping (Result<PostData, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(FirebaseError.userNotAuthenticated))
            return
        }
        
        let uid = currentUser.uid
        let postId = UUID().uuidString
        
        print("📸 전면/후면 이미지 업로드 시작 - Post ID: \(postId)")
        
        let group = DispatchGroup()
        var frontImageURL: String?
        var backImageURL: String?
        var uploadError: Error?
        
        group.enter()
        uploadImage(image: frontImage, path: "rooms/\(roomId)/posts/\(postId)/front.jpg") { result in
            switch result {
            case .success(let url):
                frontImageURL = url
                print("✅ 전면 이미지 업로드 성공")
            case .failure(let error):
                uploadError = error
                print("❌ 전면 이미지 업로드 실패: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        uploadImage(image: backImage, path: "rooms/\(roomId)/posts/\(postId)/back.jpg") { result in
            switch result {
            case .success(let url):
                backImageURL = url
                print("✅ 후면 이미지 업로드 성공")
            case .failure(let error):
                uploadError = error
                print("❌ 후면 이미지 업로드 실패: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let error = uploadError {
                print("❌ 이미지 업로드 중 오류 발생: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let frontURL = frontImageURL, let backURL = backImageURL else {
                print("❌ 이미지 URL이 없음")
                completion(.failure(FirebaseError.uploadFailed))
                return
            }
            
            print("✅ 전면/후면 이미지 업로드 모두 완료")
            
            let postData = PostData(postId: postId, uid: uid, frontImageURL: frontURL, backImageURL: backURL, caption: caption, stickerPostId: "", stickerType: "null")
            self.savePostToRoom(roomId: roomId, postId: postId, postData: postData, completion: completion)
        }
    }
    
    private func savePostToRoom(roomId: String, postId: String, postData: PostData, completion: @escaping (Result<PostData, Error>) -> Void) {
        let batch = db.batch()
        
        do {
            var dict = try Firestore.Encoder().encode(postData)
            dict["uid"] = postData.uid
            dict["createdAt"] = FieldValue.serverTimestamp()
            dict["updatedAt"] = FieldValue.serverTimestamp()
            
            let postRef = db.collection("Rooms").document(roomId)
                .collection("posts").document(postId)
            
            let userRef = db.collection("Users").document(postData.uid)
            
            batch.setData(dict, forDocument: postRef, merge: true)
            batch.setData(["recentPostId": postId,
                           "updatedAt": FieldValue.serverTimestamp()],
                          forDocument: userRef,
                          merge: true)
            
            batch.commit { error in
                if let error = error {
                    print("Room post 저장 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Room post 저장 성공: \(roomId)/posts/\(postId)")
                    completion(.success(postData))
                }
            }
        } catch {
            print("PostData 직렬화 실패: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    func fetchRoomPosts(roomId: String, completion: @escaping (Result<[PostData], Error>) -> Void) {
        print("📥 Room posts 조회 시작: \(roomId)")
        
        db.collection("Rooms").document(roomId).collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Room posts 조회 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📄 posts 문서가 없음")
                    completion(.success([]))
                    return
                }
                
                print("📄 \(documents.count)개 posts 문서 발견")
                
                let postsList = documents.compactMap { document -> PostData? in
                    try? document.data(as: PostData.self)
                }
                
                print("✅ \(postsList.count)개 posts 데이터 파싱 완료")
                completion(.success(postsList))
            }
    }
    
    func fetchTodayRoomPosts(roomId: String, completion: @escaping (Result<[PostData], Error>) -> Void) {
        print("📅 오늘 찍은 Room posts 조회 시작: \(roomId)")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayTimestamp = Timestamp(date: today)
        
        print("📅 오늘 날짜: \(today)")
        
        db.collection("Rooms").document(roomId).collection("posts")
            .whereField("createdAt", isGreaterThanOrEqualTo: todayTimestamp)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 오늘 posts 조회 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📄 오늘 posts 문서가 없음")
                    completion(.success([]))
                    return
                }
                
                print("📄 \(documents.count)개 오늘 posts 문서 발견")
                
                let postsList = documents.compactMap { document -> PostData? in
                    try? document.data(as: PostData.self)
                }
                
                print("✅ \(postsList.count)개 오늘 posts 데이터 파싱 완료")
                completion(.success(postsList))
            }
    }
    
    func downloadImage(from urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(FirebaseError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(.failure(FirebaseError.imageDownloadFailed))
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(image))
            }
        }.resume()
    }
    
    
    private func uploadImage(image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("🚀 이미지 업로드 시작 - 경로: \(path)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 이미지 변환 실패")
            completion(.failure(FirebaseError.imageConversionFailed))
            return
        }
        
        print("✅ 이미지 변환 성공 - 크기: \(imageData.count) bytes")
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("📤 Firebase Storage에 업로드 시작...")
        
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Storage 업로드 실패: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Storage 업로드 성공!")
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ 다운로드 URL 생성 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    print("❌ 다운로드 URL이 nil")
                    completion(.failure(FirebaseError.downloadURLFailed))
                    return
                }
                
                print("✅ 다운로드 URL 생성 성공: \(downloadURL.absoluteString)")
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
}

enum FirebaseError: LocalizedError {
    case uploadFailed
    case imageConversionFailed
    case downloadURLFailed
    case userNotAuthenticated
    case userDocumentNotFound
    case roomIdNotFound
    case invalidURL
    case imageDownloadFailed
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed:
            return "이미지 업로드에 실패했습니다"
        case .imageConversionFailed:
            return "이미지 변환에 실패했습니다"
        case .downloadURLFailed:
            return "다운로드 URL 생성에 실패했습니다"
        case .userNotAuthenticated:
            return "사용자가 인증되지 않았습니다"
        case .userDocumentNotFound:
            return "사용자 문서를 찾을 수 없습니다"
        case .roomIdNotFound:
            return "roomId를 찾을 수 없습니다"
        case .invalidURL:
            return "유효하지 않은 URL입니다"
        case .imageDownloadFailed:
            return "이미지 다운로드에 실패했습니다"
        }
    }
}
