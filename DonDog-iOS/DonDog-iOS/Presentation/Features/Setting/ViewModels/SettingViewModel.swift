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
    func logout() async {
        NotificationService.shared.deleteFCMToken() { error in
            if let error = error {
                print("FCM 토큰 삭제 실패(로그아웃 계속 진행): \(error.localizedDescription)")
            }
        }
        
        do {
            try Auth.auth().signOut()
            Task { @MainActor in
                ConnectStateService.shared.reset()
            }
            // 메인에서 세션 리셋 + 캐시 제거
            await MainActor.run {
                ModuleFactory.shared.resetSession()
                URLCache.shared.removeAllCachedResponses()
            }
            print("로그아웃 성공")
        } catch {
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }
}
