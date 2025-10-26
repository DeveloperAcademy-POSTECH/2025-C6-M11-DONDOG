//
//  DataManagerProtocol.swift
//  DonDog-iOS
//
//  Created by Ito on 10/26/25.
//

import UIKit

protocol DataManagerProtocol {
    // MARK: - Firestore 읽기
    /// 단일 문서 조회
    func fetch<T: Decodable>(path: String) async throws -> T
    
    /// 컬렉션 전체 조회
    func fetchCollection<T: Decodable>(path: String) async throws -> [T]
    
    /// 정렬된 컬렉션 조회
    func fetchCollection<T: Decodable>(path: String, orderBy field: String, descending: Bool) async throws -> [T]
    
    // MARK: - Firestore 쓰기
    
    /// 문서 생성 (ID 지정)
    func create(path: String, data: [String: Any]) async throws
    
    /// 문서 생성 (ID 자동 생성)
    func createWithAutoId(path: String, data: [String: Any]) async throws -> String
    
    /// 문서 업데이트
    func update(path: String, data: [String: Any]) async throws
    
    /// 문서 삭제
    func delete(path: String) async throws
    
    /// Batch 업데이트
    func batchUpdate(updates: [(path: String, data: [String: Any])]) async throws
    
    // MARK: - Storage
    
    /// 이미지 업로드
    func uploadImage(image: UIImage, path: String) async throws -> String
    
    /// 이미지 다운로드
    func downloadImage(from urlString: String) async throws -> UIImage
    
    // MARK: - Auth
    
    /// 현재 사용자 ID
    func getCurrentUserId() -> String?
}
