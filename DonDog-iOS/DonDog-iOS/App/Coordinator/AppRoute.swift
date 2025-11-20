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
    case home
    case stickerCollection
    case archive
    case post(post: PostData, postType: PostType)
    case setting
    case editprofile
    case photoPicker
}
