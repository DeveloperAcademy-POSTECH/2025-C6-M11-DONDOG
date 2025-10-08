//
//  PhotoSaveService.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/6/25.
//

import Combine
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit

struct ImageData: Codable {
    let id: String
    let frontImageURL: String
    let backImageURL: String
    let createdAt: Timestamp
    let userId: String
    
    init(frontImageURL: String, backImageURL: String, userId: String = "test_user") {
        self.id = UUID().uuidString
        self.frontImageURL = frontImageURL
        self.backImageURL = backImageURL
        self.createdAt = Timestamp()
        self.userId = userId
    }
}


final class PhotoSaveService: ObservableObject {
    static let shared = PhotoSaveService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    func uploadImages(frontImage: UIImage, backImage: UIImage, completion: @escaping (Result<ImageData, Error>) -> Void) {
        print("🎯 uploadImages 시작")
        let imageData = ImageData(frontImageURL: "", backImageURL: "", userId: "test_user")
        print("📋 생성된 이미지 ID: \(imageData.id)")
        
        let group = DispatchGroup()
        var frontImageURL: String?
        var backImageURL: String?
        var uploadError: Error?
        
        group.enter()
        uploadImage(image: frontImage, path: "images/\(imageData.id)/front.jpg") { result in
            switch result {
            case .success(let url):
                frontImageURL = url
            case .failure(let error):
                uploadError = error
            }
            group.leave()
        }
        
        group.enter()
        uploadImage(image: backImage, path: "images/\(imageData.id)/back.jpg") { result in
            switch result {
            case .success(let url):
                backImageURL = url
            case .failure(let error):
                uploadError = error
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
                return
            }
            
            guard let frontURL = frontImageURL, let backURL = backImageURL else {
                completion(.failure(FirebaseError.uploadFailed))
                return
            }
            
            let finalImageData = ImageData(
                frontImageURL: frontURL,
                backImageURL: backURL,
                userId: imageData.userId
            )
            
            self.saveImageDataToFirestore(imageData: finalImageData, completion: completion)
        }
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
    
    private func saveImageDataToFirestore(imageData: ImageData, completion: @escaping (Result<ImageData, Error>) -> Void) {
        do {
            try db.collection("images").document(imageData.id).setData(from: imageData) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(imageData))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchImageData(completion: @escaping (Result<[ImageData], Error>) -> Void) {
        print("📥 Firebase에서 이미지 목록 가져오기 시작")
        db.collection("images")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore 조회 실패: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📄 문서가 없음")
                    completion(.success([]))
                    return
                }
                
                print("📄 \(documents.count)개 문서 발견")
                
                let imageDataList = documents.compactMap { document -> ImageData? in
                    try? document.data(as: ImageData.self)
                }
                
                print("✅ \(imageDataList.count)개 이미지 데이터 파싱 완료")
                completion(.success(imageDataList))
            }
    }
}

enum FirebaseError: LocalizedError {
    case uploadFailed
    case imageConversionFailed
    case downloadURLFailed
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed:
            return "이미지 업로드에 실패했습니다"
        case .imageConversionFailed:
            return "이미지 변환에 실패했습니다"
        case .downloadURLFailed:
            return "다운로드 URL 생성에 실패했습니다"
        }
    }
}
