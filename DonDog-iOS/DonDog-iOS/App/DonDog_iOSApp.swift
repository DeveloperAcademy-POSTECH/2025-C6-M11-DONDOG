//
//  DonDog_iOSApp.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct DonDog_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            let factory = ModuleFactory.shared
            let coordinator = AppCoordinator(factory: factory)
            RootNavigationView(coordinator: coordinator)
                .onOpenURL { url in
                    _ = Auth.auth().canHandle(url)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    /// 앱 실행 시 Firebase 초기화 및 원격 알림 등록
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        return true
    }
    /// Firebase Auth 전화번호 인증 관련: reCAPTCHA/인증 푸시 알림 처리
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // FirebaseAuth가 처리해야 하는 푸시 알림이면 여기서 핸들링
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        // 만약 다른 알림 로직 있으면 여기서 처리 (없으면 아래 코드는 유지)
        completionHandler(.newData)
    }
    /// Firebase Auth 전화번호 인증 관련: APNs 디바이스 토큰을 Firebase Auth로 전달
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }
    /// Firebase Auth 전화번호 인증 관련: reCAPTCHA 콜백 URL 처리
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
}
