//
//  ConnectState.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/19/25.
//

import Foundation
import Combine

@MainActor
final class ConnectStateService: ObservableObject {
    static let shared = ConnectStateService()
    private init() {}
    
    @Published var isConnected: Bool = false
    @Published var roomId: String? = nil
    
    func reset() {
        self.isConnected = false
        self.roomId = nil
    }
}
