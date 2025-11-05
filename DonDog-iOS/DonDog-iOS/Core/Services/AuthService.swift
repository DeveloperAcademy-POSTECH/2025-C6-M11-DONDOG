//
//  AuthService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/5/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Foundation

final class AuthService {
    static var isAccountDeletionInProgress: Bool = false
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userDocListenr: ListenerRegistration?
    private var reconfigureObserver: NSObjectProtocol?
    private weak var coordinatorRef: AppCoordinator?

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        if let listener = userDocListenr {
            listener.remove()
        }
        if let obs = reconfigureObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // MARK: - 라우팅 진입점/코어
    func configureAuthBasedRouting(coordinator: AppCoordinator) {
        self.coordinatorRef = coordinator
        applyRouteForUser(coordinator: coordinator)
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            guard let self = self else { return }
            self.applyRouteForUser(coordinator: coordinator)
        }
        if reconfigureObserver == nil {
            reconfigureObserver = NotificationCenter.default.addObserver(
                forName: .authServiceReconfigureRouting,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self, let coord = self.coordinatorRef else { return }
                self.applyRouteForUser(coordinator: coord)
            }
        }
    }

    private func applyRouteForUser(coordinator: AppCoordinator) {
        guard let user = Auth.auth().currentUser else {
            Task { @MainActor in
                UserPairingStore.shared.reset()
            }
            replaceRootinAuthService(.welcome, coordinator: coordinator)
            self.userDocListenr?.remove()
            self.userDocListenr = nil
            NSLog("[AuthService] currentUser 없음 → welcome 화면으로 이동")
            return
        }

        if AuthService.isAccountDeletionInProgress { return }

        user.getIDTokenResult(forcingRefresh: true) { [weak self] _, _ in
            guard let self = self else { return }
            guard let refreshUser = Auth.auth().currentUser else {
                Task { @MainActor in
                    UserPairingStore.shared.reset()
                }
                self.replaceRootinAuthService(.welcome, coordinator: coordinator)
                NSLog("[AuthService] IDToken 분실로 current User 찾을 수 없음 → welcome 화면으로 이동")
                return
            }

            Task { @MainActor in
                UserPairingStore.shared.reset()
            }

            self.uploadFCMAndSubscribe()

            let uid = refreshUser.uid
            let userDoc = Firestore.firestore().collection("Users").document(uid)

            self.userDocListenr?.remove()
            self.userDocListenr = userDoc.addSnapshotListener(includeMetadataChanges: true) { [weak self] userDoc, error in
                guard let self = self else { return }
                self.handleUserSnapshot(coordinator: coordinator, userDoc: userDoc, error: error, refreshUser: refreshUser)
            }
        }
    }

    // MARK: - 라우팅 처리 1: 라우팅 & FCM 토큰 관리
    private func replaceRootinAuthService(_ route: AppRoute, coordinator: AppCoordinator) {
        Task { @MainActor in
            if coordinator.root == route { return }
            coordinator.replaceRoot(route)
            NSLog("[AuthService replaceRootinAuthService함수] 🔄 \(coordinator.root) → \(route)")
        }
    }

    private func uploadFCMAndSubscribe() {
        Messaging.messaging().token { token, error in
            if let token = token {
                NotificationService.shared.uploadFCMToken(token)
                Messaging.messaging().subscribe(toTopic: "daily_random_notification") { error in
                    if let error = error {
                        NSLog("토픽 구독 실패: \(error.localizedDescription)")
                    } else {
                        NSLog("토픽 구독 성공")
                    }
                }
            } else if let error = error {
                NSLog("FCM 토큰 획득 실패 (AuthService): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 라우팅 처리 2: 사용자 문서 스냅샷 처리
    private func handleUserSnapshot(coordinator: AppCoordinator, userDoc: DocumentSnapshot?, error: Error?, refreshUser: User) {
        if AuthService.isAccountDeletionInProgress { return }

        // 오류 또는 스냅샷 nil 처리
        if let nsError = error as NSError? {
            NSLog("⚠️ 사용자 문서 조회 오류: \(nsError.localizedDescription) → welcome로 이동")
            Task { @MainActor in
                UserPairingStore.shared.reset()
            }
            replaceRootinAuthService(.welcome, coordinator: coordinator)
            return
        }
        guard let userDoc = userDoc else {
            Task { @MainActor in
                UserPairingStore.shared.reset()
            }
            replaceRootinAuthService(.profileSetup, coordinator: coordinator)
            return
        }

        // user 문서 없음 → 프로필 설정
        if userDoc.exists == false {
            Task { @MainActor in
                UserPairingStore.shared.reset()
            }
            replaceRootinAuthService(.profileSetup, coordinator: coordinator)
            return
        }

        // 보류 중 쓰기 → 대기
        if userDoc.metadata.hasPendingWrites { return }

        let data = userDoc.data() ?? [:]
        let roomId = data["roomId"] as? String
        processRoomRouting(coordinator: coordinator, refreshUser: refreshUser, userData: data, roomId: roomId)
    }

    // MARK: - 라우팅 처리 3:  방/페어링 상태 라우팅
    private func processRoomRouting(coordinator: AppCoordinator, refreshUser: User, userData: [String: Any], roomId: String?) {
        let state = UserPairingStore.shared
        state.myUid = refreshUser.uid
        state.myName = userData["name"] as? String

        guard let rid = roomId, !rid.isEmpty else {
            state.reset()
            NSLog("[AuthService] 🔓 미연결 상태 (roomId 없음)")
            return
        }

        Task {
            do {
                let db = Firestore.firestore()
                let roomDoc = try await db.collection("Rooms").document(rid).getDocument()
                guard let roomData = roomDoc.data(), let participants = roomData["participants"] as? [String] else {
                    state.reset()
                    replaceRootinAuthService(.welcome, coordinator: coordinator)
                    return
                }

                if let partnerUid = participants.first(where: { $0 != refreshUser.uid }) {
                    let partnerDoc = try await db.collection("Users").document(partnerUid).getDocument()
                    state.partnerUid = partnerUid
                    state.partnerName = partnerDoc.data()?["name"] as? String
                    NSLog("[AuthService] Partner Info: uid = \(partnerUid), name = \(state.partnerName ?? "nil")")
                } else {
                    state.partnerUid = nil
                    state.partnerName = nil
                }

                state.roomId = rid
                state.isConnected = true

                NSLog("[AuthService] My Info: uid = \(state.myUid ?? "nil"), name = \(state.myName ?? "nil")")
                NSLog("[AuthService] 상태: 연결 상태 =\(state.isConnected), roomId=\(state.roomId ?? "nil")")
                replaceRootinAuthService(.feed, coordinator: coordinator)
            } catch {
                NSLog("AuthService에서 정보 로딩 중 에러: \(error.localizedDescription)")
                state.reset()
                replaceRootinAuthService(.welcome, coordinator: coordinator)
            }
        }
    }
}
