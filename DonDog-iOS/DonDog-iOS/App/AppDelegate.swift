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
    var initialDeepLink: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let providerFactory = YourAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        FirebaseApp.configure()

        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            NSLog("권한 요청: \(granted)")
            UNUserNotificationCenter.current().getNotificationSettings { setting in
                if setting.authorizationStatus == .authorized || setting.authorizationStatus == .provisional {
                    DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
                }
            }
        }

        // FCM 토큰/메시징 델리게이트
        Messaging.messaging().delegate = self
        ensureFCMTokenAndSubscribe()

        if let storedToken = NotificationService.shared.getTokenFromUserDefaults() {
            NSLog("UserDefaults에 FCM 토큰 저장: \(storedToken)")
        } else {
            NSLog("UserDefaults에 FCM 토큰 없음")
        }

        // 앱이 종료된 상태에서 푸시 알림 실행 시 딥링크를 저장
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            if let link = userInfo["link"] as? String {
                print("앱 실행 시 딥링크 처리: \(userInfo)")
                self.initialDeepLink = link
            }
        }
        return true
    }

    // 전화번호 가입 관련 함수
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // FirebaseAuth가 처리해야 하는 푸시 알림이면 여기서 핸들링
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        // 만약 다른 알림 로직 있으면 여기서 처리 (없으면 아래 코드는 유지)
        completionHandler(.newData)
    }

    // APNs device token → Firebase Auth
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // FCM
        Messaging.messaging().apnsToken = deviceToken

    }

    private func userNotificationCenter(
        center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("APNs 등록 실패: \(error.localizedDescription)")
    }

    // Handle custom URL scheme for reCAPTCHA callback & deeplinks
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Firebase Auth (reCAPTCHA)
        if Auth.auth().canHandle(url) {
            return true
        }

        // Custom URL Scheme (deeplink)
        if let scheme = url.scheme, scheme == "dondog" {
            NotificationCenter.default.post(name: .openDeepLink, object: url.absoluteString)
            return true
        }

        return false
    }

    // FCM MessagingDelegate - FCM이 토큰을 갱신하면 사용, APNs 토큰이 이미 있다면 여기서 구독 시도
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        NSLog("FCM 토큰 (delegate): \(token)")
        NotificationService.shared.uploadFCMToken(token)
    }

    // 푸시 알림을 누르면 포함된 link의 정보를 추출하여 딥링크 수행
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        NSLog("tapped notification: \(userInfo)")
        if let link = userInfo["link"] as? String {
            NotificationCenter.default.post(name: .openDeepLink, object: link)
        }
    }

    private func ensureFCMTokenAndSubscribe() {
        Messaging.messaging().token { token, error in
            if let token {
                NotificationService.shared.uploadFCMToken(token)

            } else if let error {
                NSLog("초기 토큰 획득 실패: \(error.localizedDescription)")
            }
        }
    }
}
