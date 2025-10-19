//
//  AppDelegate.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/4/25.
//

import FirebaseAppCheck
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import SwiftUI
import UserNotifications

class YourAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return DeviceCheckProvider(app: app)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let providerFactory = YourAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        FirebaseApp.configure()
        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, err in
            print("권한 요청: \(granted), 에러: \(String(describing: err))")
        }
        
        // 원격 알림 등록
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        // FCM 토큰/메시징 델리게이트
        Messaging.messaging().delegate = self
        
        // 로그인 상태 변화에도 토큰 업로드
            Auth.auth().addStateDidChangeListener { _, user in
                guard user != nil else { return }
                Messaging.messaging().token { token, _ in
                    if let token = token {
                        self.uploadTokenToServer(token)
                    }
                }
            }
        return true
    }
    
    // 전화번호 가입 관련 함수
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
    
    // APNs device token → Firebase Auth
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Firebase Auth (전화번호 인증용)
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        
        // FCM
        Messaging.messaging().apnsToken = deviceToken
        
        Messaging.messaging().token { token, error in
            guard let token = token else { return }
            print("FCM 토큰 (post-APNs): \(token)")
            self.uploadTokenToServer(token)
        }
    }
    
    // Handle custom URL scheme for reCAPTCHA callback
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
    
    // FCM MessagingDelegate - FCM이 토큰을 갱신하면 사용, APNs 토큰이 이미 있다면 여기서 구독 시도
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM 토큰 (delegate): \(token)")
        self.uploadTokenToServer(token)
        self.subscribeDailyTopic()
    }
    
    // UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        print("tapped notification: \(userInfo)")
        if let deeplink = userInfo["deeplink"] as? String {
            NotificationCenter.default.post(name: .openDeepLink, object: deeplink)
        }
        completionHandler()
    }
    
    private func subscribeDailyTopic() {
        Messaging.messaging().subscribe(toTopic: "daily_random_notification") { error in
            if let error = error {
                print("토픽 구독 에러: \(error.localizedDescription)")
            } else {
                print("daily_random_notification 구독 성공")
            }
        }
    }
    
    private func uploadTokenToServer(_ token: String) {
            guard let uid = Auth.auth().currentUser?.uid else {
                print("⚠️ 현재 로그인한 사용자 없음 — 로그인 이후 다시 업로드 필요")
                return
            }
            NotificationService.shared.uploadFCMToken(token)
            print("Firestore에 FCM 토큰 업로드 완료: \(token)")
        }

}
