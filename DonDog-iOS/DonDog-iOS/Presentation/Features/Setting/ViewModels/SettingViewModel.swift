//
//  SettingViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/9/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class SettingViewModel: ObservableObject {
    @Published var showLogoutConfirm = false
    @Published var showDeleteConfirm = false
    func logout() async {
        do {
            try await NotificationService.shared.deleteFCMToken()
        } catch {
            NSLog("FCM 토큰 삭제 실패(로그아웃 계속 진행): \(error.localizedDescription)")
        }
        
        do {
            try Auth.auth().signOut()
            // 메인에서 세션 리셋 + 캐시 제거
            await MainActor.run {
                URLCache.shared.removeAllCachedResponses()
                
            }
            NSLog("로그아웃 성공")
        } catch {
            NSLog("로그아웃 실패: \(error.localizedDescription)")
        }
    }
}
