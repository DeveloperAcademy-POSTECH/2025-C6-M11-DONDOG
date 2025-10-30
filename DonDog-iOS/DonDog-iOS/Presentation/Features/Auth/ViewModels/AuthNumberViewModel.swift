//
//  AuthViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class AuthNumberViewModel: ObservableObject {
    private weak var coordinator: AppCoordinator?
    private let dataManager: DataManagerProtocol = DataManager.shared

    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
    }

    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    @Published var verificationCode: String = ""
    @Published var verificationID: String?
    
    @Published var message: String = ""
    @Published var isLoading: Bool = false
    @Published var codeError: String? = nil
    
    @Published var isNumberWithdraw = false
    @Published var showWithdrawErrorAlert = false
    @Published var alertMessage: String? = nil
    
    init(isNumberWithdraw: Bool = false) {
        self.isNumberWithdraw = isNumberWithdraw
    }
    
    /// 인증번호로 로그인
    func logIn() {
        // verifyPhoneNumber로 받은 verificationID 확보
        let storedID = UserDefaults.standard.string(forKey: "authVerificationID")
        guard let verificationID = self.verificationID ?? storedID else {
            self.codeError = "문제가 생겼어요. 잠시 후 다시 시도해 주세요."
            return
        }
        
        self.isLoading = true
        self.message = ""
        self.codeError = nil
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: self.verificationCode
        )
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("[Auth][signIn] error: \(error.localizedDescription)")
                    self.codeError = "인증번호를 다시 확인해주세요."
                    self.isLoading = false
                } else {
                    self.codeError = nil
                    print("[Auth][signIn] 인증 성공")
                    if let user = Auth.auth().currentUser {
                        print("전화번호:", user.phoneNumber ?? "없음")
                    }
                    if self.isNumberWithdraw == true {
                        print("[Auth][signIn] 탈퇴 시작")
                        self.performAccountDeletion()
                    } else {
                        print("[Auth][signIn] 로그인 성공")
                        self.routeAfterLogin()
                    }
                }
            }
        }
    }
    
    private func routeAfterLogin() {
        Task {
            guard let uid = dataManager.getCurrentUserId(), !uid.isEmpty else { return }
            
            struct ExistsUserDoc: Decodable {}
            let exists: Bool
            do {
                let _: ExistsUserDoc = try await dataManager.fetch(path: "Users/\(uid)")
                exists = true
            } catch {
                exists = false
            }
            
            await MainActor.run {
                if exists {
                    self.coordinator?.replaceRoot(.feed)
                } else {
                    self.coordinator?.replaceRoot(.profileSetup)
                }
            }
        }
    }
    
    private func performAccountDeletion() {
        Task {
            await MainActor.run {
                AuthService.isAccountDeletionInProgress = true
            }
            let success = await deleteUserDataAndAuth()
            await MainActor.run {
                if success {
                    self.coordinator?.replaceRoot(.welcome)
                }
                NotificationCenter.default.post(name: .authServiceReconfigureRouting, object: nil)
            }
        }
    }
    
    private func deleteUserDataAndAuth() async -> Bool {
        guard let user = Auth.auth().currentUser else {
            print("[회원탈퇴] 로그인 정보를 찾을 수 없습니다")
            return false
        }
        
        await MainActor.run {
            AuthService.isAccountDeletionInProgress = true
        }

        let uid = user.uid
        let db = Firestore.firestore()

        do {
            // 1) Firestore 정리
            // Users/{uid}를 읽어 roomId 확인
            let userDoc = db.collection("Users").document(uid)
            let userData = try await userDoc.getDocument()
            var roomId: String? = nil
            if let data = userData.data(), let rid = data["roomId"] as? String, !rid.isEmpty {
                roomId = rid
            }

            // Rooms
            var roomDocToCheck: [DocumentReference] = []
            if let rid = roomId, !rid.isEmpty {
                roomDocToCheck.append(db.collection("Rooms").document(rid))
            }
            // 재확인 - participants 배열에 내 uid가 포함된 모든 방을 역으로 검색
            let roomsDoc = db.collection("Rooms").whereField("participants", arrayContains: uid)
            let roomData = try await roomsDoc.getDocuments()
            roomDocToCheck.append(contentsOf: roomData.documents.map { $0.reference })

            // 중복된 후보 제거
            var uniqueRids = [String: DocumentReference]()
            for roomDoc in roomDocToCheck {
                uniqueRids[roomDoc.path] = roomDoc
            }

            // 1-1) participants에서 내가 마지막 유저인지 확인
            // 1-1-1) 내가 마지막 유저라면 - rooms 모두 삭제, storage 삭제
            // 1-1-2) 내가 마지막 유저가 아니라면 - participants에서만 나 삭제
            
            // 각 Room 처리: 마지막 참가자면 Storage → posts → comments → Room 삭제, 아니면 participants에서 내 uid만 제거
            for (_, roomDoc) in uniqueRids {
                // 최신 스냅샷 확인
                let snap = try await roomDoc.getDocument()
                guard let data = snap.data(), let parts = data["participants"] as? [String], parts.contains(uid) else { continue }

                if parts.count > 1 {
                    // 2명이상 → participants에서 내 uid만 제거
                    try await dataManager.update(path: roomDoc.path, data: ["participants": FieldValue.arrayRemove([uid])])
                    do {
                        let verifySnap = try await roomDoc.getDocument(source: .server)
                        _ = (verifySnap.data()?["participants"] as? [String]) ?? []
                    } catch {
                        _ = error as NSError
                    }
                } else {
                    // 마지막 1명(본인) → 모든 Rooms 데이터, storage 삭제
                    // 1) posts storage 삭제
                    let postsSnap = try await roomDoc.collection("posts").getDocuments()
                    func isFirebaseStorageURL(_ s: String) -> Bool {
                        s.hasPrefix("https://firebasestorage.googleapis.com") || s.hasPrefix("gs://")
                    }
                    func collectStorageURLs(from any: Any, into result: inout [String]) {
                        switch any {
                        case let s as String:
                            if isFirebaseStorageURL(s) { result.append(s) }
                        case let arr as [Any]:
                            for v in arr { collectStorageURLs(from: v, into: &result) }
                        case let dict as [String: Any]:
                            for (_, v) in dict { collectStorageURLs(from: v, into: &result) }
                        default:
                            break
                        }
                    }
                    
                    var urlsToDelete: [String] = []
                    for doc in postsSnap.documents { collectStorageURLs(from: doc.data(), into: &urlsToDelete) }
                    urlsToDelete = Array(Set(urlsToDelete))
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        for url in urlsToDelete {
                            group.addTask { try await self.dataManager.deleteStorageFile(urlString: url) }
                        }
                        try await group.waitForAll()
                    }

                    // 2) posts 삭제
                    if !postsSnap.isEmpty {
                        let postPaths = postsSnap.documents.map { $0.reference.path }
                        try await dataManager.batchDelete(paths: postPaths)
                    }

                    // 3) comments 삭제
                    let postIds = postsSnap.documents.map { $0.documentID }
                    for postId in postIds {
                        let commentRef = roomDoc.collection("comments").document(postId) // Rooms/{roomId}/comments/{postId}
                        let subCommentsRef = commentRef.collection("comments")       // Rooms/{roomId}/comments/{postId}/comments

                        if let subCommentsSnap = try? await subCommentsRef.getDocuments(), !subCommentsSnap.isEmpty {
                            let subCommentsPaths = subCommentsSnap.documents.map { $0.reference.path }
                            try await dataManager.batchDelete(paths: subCommentsPaths)
                        }
                        
                        try await dataManager.delete(path: commentRef.path)
                    }
                    // 4) Room 문서 삭제
                    try await dataManager.delete(path: roomDoc.path)
                }
            }
            
            // 1-2) Invites 에서 uid가 있는 문서 삭제
            let invitesDoc = db.collection("Invites")
            let inviterQuery = invitesDoc.whereField("inviterUid", isEqualTo: uid)
            let inviterData = try await inviterQuery.getDocuments()
            if !inviterData.isEmpty {
                let invitePaths = inviterData.documents.map { $0.reference.path }
                try await dataManager.batchDelete(paths: invitePaths)
            }
            
            // 1-3) Users/{uid} 삭제 (하위 fcmTokens 먼저 삭제)
            do {
                let tokensSnap = try await userDoc.collection("fcmTokens").getDocuments()
                if !tokensSnap.isEmpty {
                    let tokenPaths = tokensSnap.documents.map { $0.reference.path }
                    try await dataManager.batchDelete(paths: tokenPaths)
                }
            }
            // Users/{uid} 문서 삭제
            try await dataManager.delete(path: userDoc.path)

            // 2) Firebase Auth 사용자 삭제
            do {
                try await user.delete()
                return true
            } catch {
                let nsError = error as NSError
                if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    print("[회원탈퇴] requiresRecentLogin: 최근 로그인 후 다시 시도 필요")
                    await MainActor.run {
                        self.showWithdrawErrorAlert = true
                        self.alertMessage = "탈퇴 중 오류가 생겼습니다. 다시 시도해주세요."
                    }
                } else {
                    print("[회원탈퇴] Auth 삭제 중 오류: \(nsError.localizedDescription)")
                    await MainActor.run {
                        self.showWithdrawErrorAlert = true
                        self.alertMessage = "탈퇴 중 오류가 생겼습니다. 다시 시도해주세요."
                    }
                }
                return false
            }
        } catch {
            let nsError = error as NSError
            print("[회원탈퇴] 오류: \(nsError.localizedDescription)")
            await MainActor.run {
                self.showWithdrawErrorAlert = true
                self.alertMessage = "탈퇴 중 오류가 생겼습니다. 다시 시도해주세요."
            }
            return false
        }
    }
}
