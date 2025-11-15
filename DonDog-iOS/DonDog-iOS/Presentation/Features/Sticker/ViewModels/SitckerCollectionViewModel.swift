//
//  SitckerCollectionViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/4/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import Kingfisher
import PhotosUI
import SwiftUI

final class SitckerCollectionViewModel: ObservableObject {
    @Published var showMakeStickerButton: Bool = false
    @Published var targetItemID: StickerItem.ID?
    
    @Published var pickedImage: UIImage?
    @Published var capturedImage: UIImage?
    
    private let dataManager: DataManagerProtocol = DataManager.shared
}
