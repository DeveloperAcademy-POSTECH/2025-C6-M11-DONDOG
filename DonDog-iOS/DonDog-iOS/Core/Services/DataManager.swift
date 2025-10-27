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

final class FirebaseDataManager: DataManagerProtocol{
    
    static let shared = FirebaseDataManager()
    private init() {}
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func fetch<T>(path: String) async throws -> T where T : Decodable {
        <#code#>
    }
    
    func fetchCollection<T>(path: String) async throws -> [T] where T : Decodable {
        <#code#>
    }
    
    func fetchCollection<T>(path: String, orderBy field: String, descending: Bool) async throws -> [T] where T : Decodable {
        <#code#>
    }
    
    func create(path: String, data: [String : Any]) async throws {
        <#code#>
    }
    
    func createWithAutoId(path: String, data: [String : Any]) async throws -> String {
        <#code#>
    }
    
    func update(path: String, data: [String : Any]) async throws {
        <#code#>
    }
    
    func delete(path: String) async throws {
        <#code#>
    }
    
    func batchUpdate(updates: [(path: String, data: [String : Any])]) async throws {
        <#code#>
    }
    
    func uploadImage(image: UIImage, path: String) async throws -> String {
        <#code#>
    }
    
    func downloadImage(from urlString: String) async throws -> UIImage {
        <#code#>
    }
    
    func getCurrentUserId() -> String? {
        <#code#>
    }
    
    
}
