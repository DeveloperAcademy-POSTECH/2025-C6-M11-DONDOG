//
//  FirebaseDataManager.swift
//  DonDog-iOS
//
//  Created by Ito on 10/26/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

// MARK: - 에러 타입
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
        case .invalidPath: return "잘못된 경로입니다"
        case .documentNotFound: return "문서를 찾을 수 없습니다"
        case .decodingFailed: return "데이터 변환에 실패했습니다"
        case .imageConversionFailed: return "이미지 변환에 실패했습니다"
        case .uploadFailed: return "업로드에 실패했습니다"
        case .downloadFailed: return "다운로드에 실패했습니다"
        case .authenticationRequired: return "로그인이 필요합니다"
        case .userDocumentNotFound: return "사용자 문서를 찾을 수 없습니다"
        case .roomIdNotFound: return "roomId를 찾을 수 없습니다"
        }
    }
}

final class DataManager: DataManagerProtocol {
    static let shared = DataManager()
    init() {}
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Helper: 경로 파싱
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
        
        guard snapshot.exists else {
            throw DataManagerError.documentNotFound
        }
        
        do {
            return try snapshot.data(as: T.self)
        } catch {
            print("❌ 디코딩 실패: \(error)")
            throw DataManagerError.decodingFailed
        }
    }
    
    func fetchCollection<T: Decodable>(path: String) async throws -> [T] {
        let collectionRef = try parseCollectionPath(path)
        let snapshot = try await collectionRef.getDocuments()
        
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: T.self)
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
        
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: T.self)
            } catch {
                print("❌ 문서 \(document.documentID) 디코딩 실패: \(error)")
                return nil
            }
        }
    }
    
    func fetchWhere<T: Decodable>(
        path: String,
        field: String,
        isGreaterThanOrEqualTo value: Any,
        orderBy: String,
        descending: Bool
    ) async throws -> [T] {
        let collectionRef = try parseCollectionPath(path)
        let query = collectionRef
            .whereField(field, isGreaterThanOrEqualTo: value)
            .order(by: orderBy, descending: descending)
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: T.self)
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
    
    enum BatchOption {
        case update(path: String, data: [String: Any]) // 기존 문서에 업데이트, 문서가 없다면 누락
        case upsert(path: String, data: [String: Any]) // 기존 문서에 업데이트, 없다면 문서 생성
    }
    func batchUpdate(_ option: [BatchOption]) async throws {
        let batch = db.batch()
        for option in option {
            switch option {
            case let .update(path, data):
                let ref = try parseFirestorePath(path)
                batch.updateData(data, forDocument: ref)
            case let .upsert(path, data):
                let ref = try parseFirestorePath(path)
                batch.setData(data, forDocument: ref, merge: true)
            }
        }
        try await batch.commit()
    }
    
    // MARK: - Firestore 삭제
    func delete(path: String) async throws {
        let docRef = try parseFirestorePath(path)
        try await docRef.delete()
    }
    
    func batchDelete(paths: [String]) async throws {
        let batch = db.batch()
        
        for path in paths {
            let docRef = try parseFirestorePath(path)
            batch.deleteDocument(docRef)
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
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
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
    
    func deleteStorageFile(urlString: String) async throws {
        do {
            let storageRef = storage.reference(forURL: urlString)
            try await storageRef.delete()
        } catch {
            print("❌ Storage 파일 삭제 실패: \(error.localizedDescription)")
            
            if (error as NSError).code != StorageErrorCode.objectNotFound.rawValue {
                throw DataManagerError.downloadFailed
            }
        }
    }
    
    // MARK: - Auth
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func getCurrentUserRoomId() async throws -> String {
        guard let uid = getCurrentUserId() else {
            throw DataManagerError.authenticationRequired
        }
        
        let user: UserData = try await fetch(path: "Users/\(uid)")
        
        guard let roomId = user.roomId, !roomId.isEmpty else {
            throw DataManagerError.roomIdNotFound
        }
        
        return roomId
    }
}
