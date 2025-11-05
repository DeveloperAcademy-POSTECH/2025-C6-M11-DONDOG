//
//  UserData.swift
//  DonDog-iOS
//
//  Created by Ito on 10/27/25.
//

import FirebaseCore

struct UserData: Codable {
    let name: String
    let role: String
    let roomId: String?
    let recentPostId: String?
    let lastUploadDate: Timestamp?
    let createdAt: Timestamp?
    let updatedAt: Timestamp?

    init(name: String, role: String, roomId: String? = nil, recentPostId: String? = nil, lastUploadDate: Timestamp? = nil, createdAt: Timestamp? = nil, updatedAt: Timestamp? = nil) {
        self.name = name
        self.role = role
        self.roomId = roomId
        self.recentPostId = recentPostId
        self.lastUploadDate = lastUploadDate
        self.createdAt = createdAt ?? Timestamp()
        self.updatedAt = updatedAt ?? Timestamp()
    }
}
