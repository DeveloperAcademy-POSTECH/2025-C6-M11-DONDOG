//
//  SettingViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/9/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class SettingViewModel: ObservableObject {
    @Published var showLogoutConfirm = false
    @Published var showDeleteConfirm = false
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }
}
