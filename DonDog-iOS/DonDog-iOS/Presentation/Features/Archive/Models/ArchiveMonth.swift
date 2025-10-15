//
//  ArchiveMonth.swift
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
}
