//
//  Comment.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/11/25.
//

import FirebaseFirestore

struct Comment: Identifiable, Equatable {
    var id: String
    var uid: String
    var text: String
    var createdAt: Date

    // Equality based on unique document id
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }

    init?(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        guard let uid = data["uid"] as? String,
              let text = data["text"] as? String,
              let createdAt = data["createdAt"] as? Timestamp else {
            return nil
        }
        self.id = doc.documentID
        self.uid = uid
        self.text = text
        self.createdAt = createdAt.dateValue()
    }

    init(uid: String, text: String, createdAt: Date = Date()) {
        self.id = UUID().uuidString
        self.uid = uid
        self.text = text
        self.createdAt = createdAt
    }
}
