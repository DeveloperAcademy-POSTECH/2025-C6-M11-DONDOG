//
//  DataManager.swift
//  DonDog-iOS
//
//  Created by Ito on 10/26/25.
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

// MARK: - 에러 타입 명시
enum DataManagerError: LocalizedError {
    case invalidPath
    case documentNotFound
    case decodingFailed
    case imageConversionFailed
    case uploadFailed
    case downloadFailed
    case authenticationRequired
    case userDocumentNotFound
    case roomIdNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "잘못된 경로입니다"
        case .documentNotFound:
            return "문서를 찾을 수 없습니다"
        case .decodingFailed:
            return "데이터 변환에 실패했습니다"
        case .imageConversionFailed:
            return "이미지 변환에 실패했습니다"
        case .uploadFailed:
            return "업로드에 실패했습니다"
        case .downloadFailed:
            return "다운로드에 실패했습니다"
        case .authenticationRequired:
            return "로그인이 필요합니다"
        case .userDocumentNotFound:
            return "사용자 문서를 찾을 수 없습니다"
        case .roomIdNotFound:
            return "roomId를 찾을 수 없습니다"
        }
    }
}

final class FirebaseDataManager: DataManagerProtocol {
    
    static let shared = FirebaseDataManager()
    private init() {}
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Helper: 경로 파싱
    
    /// "Rooms/123/posts/456" → DocumentReference
    private func parseFirestorePath(_ path: String) throws -> DocumentReference {
        let components = path.split(separator: "/").map(String.init)
        guard components.count >= 2, components.count % 2 == 0 else {
            throw DataManagerError.invalidPath
        }
        
        var reference: DocumentReference?
        for i in stride(from: 0, to: components.count, by: 2) {
            let collectionName = components[i]
            let documentId = components[i + 1]
            
            if i == 0 {
                reference = db.collection(collectionName).document(documentId)
            } else {
                reference = reference?.collection(collectionName).document(documentId)
            }
        }
        
        guard let docRef = reference else {
            throw DataManagerError.invalidPath
        }
        return docRef
    }
    
    /// "Rooms/123/posts" → CollectionReference
    private func parseCollectionPath(_ path: String) throws -> CollectionReference {
        let components = path.split(separator: "/").map(String.init)
        guard components.count % 2 == 1 else {
            throw DataManagerError.invalidPath
        }
        
        if components.count == 1 {
            return db.collection(components[0])
        }
        
        var docRef: DocumentReference?
        for i in stride(from: 0, to: components.count - 1, by: 2) {
            let collectionName = components[i]
            let documentId = components[i + 1]
            
            if i == 0 {
                docRef = db.collection(collectionName).document(documentId)
            } else {
                docRef = docRef?.collection(collectionName).document(documentId)
            }
        }
        
        let finalCollectionName = components[components.count - 1]
        if let docRef = docRef {
            return docRef.collection(finalCollectionName)
        } else {
            return db.collection(finalCollectionName)
        }
    }
    
    // MARK: - Firestore 읽기
    
    func fetch<T: Decodable>(path: String) async throws -> T {
        let docRef = try parseFirestorePath(path)
        let snapshot = try await docRef.getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            throw DataManagerError.documentNotFound
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: jsonData)
        } catch {
            print("❌ 디코딩 실패: \(error)")
            throw DataManagerError.decodingFailed
        }
    }
    
    func fetchCollection<T: Decodable>(path: String) async throws -> [T] {
        let collectionRef = try parseCollectionPath(path)
        let snapshot = try await collectionRef.getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                return try decoder.decode(T.self, from: jsonData)
            } catch {
                print("❌ 문서 \(document.documentID) 디코딩 실패: \(error)")
                return nil
            }
        }
    }
    
    func fetchCollection<T: Decodable>(
        path: String,
        orderBy field: String,
        descending: Bool
    ) async throws -> [T] {
        let collectionRef = try parseCollectionPath(path)
        let query = collectionRef.order(by: field, descending: descending)
        let snapshot = try await query.getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                return try decoder.decode(T.self, from: jsonData)
            } catch {
                print("❌ 문서 \(document.documentID) 디코딩 실패: \(error)")
                return nil
            }
        }
    }
    
    // MARK: - Firestore 쓰기
    
    func create(path: String, data: [String: Any]) async throws {
        let docRef = try parseFirestorePath(path)
        try await docRef.setData(data, merge: true)
    }
    
    func createWithAutoId(path: String, data: [String: Any]) async throws -> String {
        let collectionRef = try parseCollectionPath(path)
        let docRef = try await collectionRef.addDocument(data: data)
        return docRef.documentID
    }
    
    func update(path: String, data: [String: Any]) async throws {
        let docRef = try parseFirestorePath(path)
        try await docRef.updateData(data)
    }
    
    func delete(path: String) async throws {
        let docRef = try parseFirestorePath(path)
        try await docRef.delete()
    }
    
    func batchUpdate(updates: [(path: String, data: [String: Any])]) async throws {
        let batch = db.batch()
        
        for update in updates {
            let docRef = try parseFirestorePath(update.path)
            batch.updateData(update.data, forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Storage
    
    func uploadImage(image: UIImage, path: String) async throws -> String {
        
        guard let resizedImage = image.resized(maxWidth: 1080) else {
            throw DataManagerError.imageConversionFailed
        }
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw DataManagerError.imageConversionFailed
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // 업로드
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        
        // 다운로드 URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw DataManagerError.invalidPath
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw DataManagerError.downloadFailed
        }
        
        return image
    }
    
    // MARK: - Auth
    
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
}
