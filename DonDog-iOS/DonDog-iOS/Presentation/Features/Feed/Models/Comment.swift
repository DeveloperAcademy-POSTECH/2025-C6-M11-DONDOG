//
//  Comment.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/11/25.
//

import FirebaseFirestore

struct Comment: Identifiable {
    var id: String = UUID().uuidString
    var uid: String
    var author: String
    var text: String
    var timestamp: Date

    init(uid: String, author: String, content: String, timestamp: Timestamp) {
        self.uid = uid
        self.author = author
        self.text = content
        self.timestamp = timestamp.dateValue()
    }

    init?(dict: [String: Any]) {
        guard let uid = dict["uid"] as? String,
              let author = dict["author"] as? String,
              let content = dict["content"] as? String,
              let timestamp = dict["timestamp"] as? Timestamp else { return nil }
        self.uid = uid
        self.author = author
        self.text = content
        self.timestamp = timestamp.dateValue()
    }
}
