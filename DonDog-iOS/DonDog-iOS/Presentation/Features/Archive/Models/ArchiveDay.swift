//
//  ArchiveDay.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/13/25.
//

import Foundation

struct ArchiveDay: Identifiable, Hashable {
    let id: String
    let day: Int
    let thumbnailURL: URL
    let postId: String
}
