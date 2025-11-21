//
//  UserPairingStore.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/19/25.
//

import Combine
import Foundation

enum ConnectionState {
    case unknown      // 아직 서버/스토리지에서 안 불러옴 - 홈뷰에서
    case connected
    case notConnected
}

@MainActor
final class UserPairingStore: ObservableObject {
    static let shared = UserPairingStore()
    private init() {}
    
    @Published var isConnected: ConnectionState = .unknown
    @Published var roomId: String?
    @Published var myUid: String?
    @Published var myName: String?
    @Published var myRole: String? { didSet { StickerGridService.shared.updateRole() }}
    @Published var partnerUid: String?
    @Published var partnerName: String?
    @Published var lastUploadedAt: Date?
    
    func reset() {
        self.isConnected = .unknown
        self.roomId = nil
        self.myUid = nil
        self.myName = nil
        self.partnerUid = nil
        self.partnerName = nil
        self.lastUploadedAt = nil
    }
}
