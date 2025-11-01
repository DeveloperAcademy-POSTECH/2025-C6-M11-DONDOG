//
//  UserPairingStore.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/19/25.
//

import Combine
import Foundation

@MainActor
final class UserPairingStore: ObservableObject {
    static let shared = UserPairingStore()
    private init() {}
    
    @Published var isConnected: Bool = false
    @Published var roomId: String?
    @Published var myUid: String?
    @Published var myName: String?
    @Published var partnerUid: String?
    @Published var partnerName: String?
    
    func reset() {
        self.isConnected = false
        self.roomId = nil
        self.myUid = nil
        self.myName = nil
        self.partnerUid = nil
        self.partnerName = nil
    }
}
