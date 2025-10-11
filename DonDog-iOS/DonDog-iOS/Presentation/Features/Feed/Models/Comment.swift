//
//  Comment.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/11/25.
//

import FirebaseFirestore

struct Comment: Identifiable {
    var id: String
    var uid: String
    var author: String
    var text: String
    var timestamp: Date

    init?(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        guard let uid = data["uid"] as? String,
              let author = data["author"] as? String,
              let content = data["content"] as? String,
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }
        self.id = doc.documentID
        self.uid = uid
        self.author = author
        self.text = content
        self.timestamp = timestamp.dateValue()
    }

    init(uid: String, author: String, content: String, timestamp: Timestamp) {
        self.id = ""
        self.uid = uid
        self.author = author
        self.text = content
        self.timestamp = timestamp.dateValue()
    }
}
