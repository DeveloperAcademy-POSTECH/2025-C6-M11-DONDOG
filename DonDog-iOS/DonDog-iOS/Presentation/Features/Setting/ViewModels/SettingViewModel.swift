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
        NotificationService.shared.deleteFCMToken() { error in
            if let error = error {
                print("FCM 토큰 삭제 실패(로그아웃 계속 진행): \(error.localizedDescription)")
            }
        }
        
        do {
            try Auth.auth().signOut()
            print("로그아웃 성공")
        } catch {
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }
}
