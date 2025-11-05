//
//  InviteDoc.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/30/25.
//

import FirebaseCore

struct InviteDoc: Codable {
    let inviterUid: String
    let expireDate: Timestamp?
}
