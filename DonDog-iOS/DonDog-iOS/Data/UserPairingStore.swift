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
    @Published var roomId: String? = nil
    @Published var myUid: String? = nil
    @Published var myName: String? = nil
    @Published var partnerUid: String? = nil
    @Published var partnerName: String? = nil
    
    func reset() {
        self.isConnected = false
        self.roomId = nil
        self.myUid = nil
        self.myName = nil
        self.partnerUid = nil
        self.partnerName = nil
    }
}
