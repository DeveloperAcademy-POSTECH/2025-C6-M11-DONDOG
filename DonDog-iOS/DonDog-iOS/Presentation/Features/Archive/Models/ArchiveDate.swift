//
//  ArchiveDate.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/13/25.
//

import Foundation

struct ArchiveMonth: Identifiable, Hashable {
    let id: String
    let year: Int
    let month: Int
    var days: [ArchiveDay]
    
    // Date 객체로 변환
    var date: Date {
        let components = DateComponents(year: year, month: month)
        return Calendar.current.date(from: components) ?? Date()
    }
}

struct ArchiveDay: Identifiable, Hashable {
    let id: String
    let day: Int
    let thumbnailURL: URL
    let postId: String
}
