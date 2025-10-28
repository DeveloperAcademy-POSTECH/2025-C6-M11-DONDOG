//
//  AppRoute.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case welcome
    case auth
    case authNumber
    case profileSetup
    case invite
    case camera
    case feed
    case post(postId: String, roomId: String)
    case setting
    case editprofile
    case archive
    case archiveDetail(roomId: String, date: Date, initialPosts: [ArchivePost])
}
