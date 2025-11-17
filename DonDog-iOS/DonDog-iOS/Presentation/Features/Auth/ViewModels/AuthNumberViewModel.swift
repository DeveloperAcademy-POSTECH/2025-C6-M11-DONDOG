//
//  AuthViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

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
    @Published var codeError: String?
    
    @Published var isNumberWithdraw = false
    @Published var showWithdrawErrorAlert = false
    @Published var alertMessage: String?
    
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
        
        Auth.auth().signIn(with: credential) { [weak self] _, error in
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
                    self.coordinator?.replaceRoot(.home)
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
            // 1) 내가 속한 Room 문서 목록 수집
            let roomRefs = try await fetchRoomReferences(db: db, uid: uid)

            // 2) 각 Room 정리 (participants 제거 또는 전체 삭제)
            try await processRooms(db: db, uid: uid, roomRefs: roomRefs)

            // 3) 초대장 정리
            try await deleteInvites(db: db, uid: uid)

            // 4) Users/{uid} 하위 토큰 및 문서 삭제
            try await deleteUserTokensAndDoc(db: db, uid: uid)

            // 5) Firebase Auth 사용자 삭제
            return await deleteAuth(user: user)
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

    // MARK: - Deletion Helpers

    /// Users/{uid}.roomId와 participants 역검색을 통해 Room 문서 레퍼런스를 모두 수집한다.
    private func fetchRoomReferences(db: Firestore, uid: String) async throws -> [DocumentReference] {
        var refs: [DocumentReference] = []

        // Users/{uid}.roomId 확인
        let userDoc = db.collection("Users").document(uid)
        let userSnap = try await userDoc.getDocument()
        if let data = userSnap.data(), let rid = data["roomId"] as? String, !rid.isEmpty {
            refs.append(db.collection("Rooms").document(rid))
        }

        // participants에 uid 포함된 모든 Room 역검색
        let querySnap = try await db.collection("Rooms")
            .whereField("participants", arrayContains: uid)
            .getDocuments()

        refs.append(contentsOf: querySnap.documents.map { $0.reference })

        // 중복 제거 (path 기준)
        var unique: [String: DocumentReference] = [:]
        for r in refs { unique[r.path] = r }
        return Array(unique.values)
    }

    /// 각 Room을 순회하며 무조건 방 전체를 삭제한다.
    /// 단, participants가 2명 이상(=상대방 존재)이면 상대방의 `Users/{uid}.roomId` 필드를 제거한 뒤 방/게시물/댓글/스토리지 파일까지 정리한다.
    private func processRooms(db: Firestore, uid: String, roomRefs: [DocumentReference]) async throws {
        for roomRef in roomRefs {
            let snap = try await roomRef.getDocument()
            guard let data = snap.data(), let parts = data["participants"] as? [String], parts.contains(uid) else { continue }

            // 상대방 uid 목록(현재 uid 제외)
            let partnerIds = parts.filter { $0 != uid }

            // participants가 2명 이상이면: 상대방 Users/{uid}.roomId 제거
            if !partnerIds.isEmpty {
                for partnerUid in partnerIds {
                    let partnerUserPath = "Users/\(partnerUid)"
                    do {
                        try await dataManager.update(path: partnerUserPath, data: [
                            "roomId": FieldValue.delete(),
                            "recentPostId": FieldValue.delete()
                        ])
                    } catch {
                        try? await dataManager.update(path: partnerUserPath, data: [
                            "roomId": "",
                            "recentPostId": ""
                        ])
                    }
                }
            }

            // 규칙: 참가자 수와 무관하게 방 전체 삭제
            try await deleteEntireRoom(roomRef: roomRef)
        }
    }

    /// Room 전체 정리: Storage 파일 삭제 → posts 삭제 → comments 트리 삭제 → Room 삭제
    private func deleteEntireRoom(roomRef: DocumentReference) async throws {
        // 1) posts 수집
        let postsSnap = try await roomRef.collection("posts").getDocuments()

        // 1-1) Storage URL 수집 및 삭제
        var urlsToDelete: [String] = []
        for doc in postsSnap.documents {
            collectStorageURLs(from: doc.data(), into: &urlsToDelete)
        }
        urlsToDelete = Array(Set(urlsToDelete))
        try await withThrowingTaskGroup(of: Void.self) { group in
            for url in urlsToDelete {
                group.addTask { try await self.dataManager.deleteStorageFile(urlString: url) }
            }
            try await group.waitForAll()
        }

        // 2) posts 문서 일괄 삭제
        if !postsSnap.isEmpty {
            let postPaths = postsSnap.documents.map { $0.reference.path }
            try await dataManager.batchDelete(paths: postPaths)
        }

        // 3) comments 트리 삭제
        let postIds = postsSnap.documents.map { $0.documentID }
        for postId in postIds {
            // Rooms/{roomId}/comments/{postId}/comments (실제 댓글들)
            let commentDoc = roomRef.collection("comments").document(postId)
            let subCommentsRef = commentDoc.collection("comments")

            if let subCommentsSnap = try? await subCommentsRef.getDocuments(), !subCommentsSnap.isEmpty {
                let subCommentPaths = subCommentsSnap.documents.map { $0.reference.path }
                try await dataManager.batchDelete(paths: subCommentPaths)
            }
            // 상위 comment 컨테이너 문서 삭제
            try await dataManager.delete(path: commentDoc.path)
        }

        // 4) 마지막으로 Room 삭제
        try await dataManager.delete(path: roomRef.path)
    }

    /// Invites 컬렉션에서 uid가 관여한 문서 삭제
    private func deleteInvites(db: Firestore, uid: String) async throws {
        let invites = db.collection("Invites")

        // 내가 초대한 문서
        let inviterSnap = try await invites.whereField("inviterUid", isEqualTo: uid).getDocuments()
        if !inviterSnap.isEmpty {
            let paths = inviterSnap.documents.map { $0.reference.path }
            try await dataManager.batchDelete(paths: paths)
        }
    }

    /// Users/{uid} 하위 fcmTokens 먼저 삭제 후, Users 문서 삭제
    private func deleteUserTokensAndDoc(db: Firestore, uid: String) async throws {
        let userDoc = db.collection("Users").document(uid)
        let tokensSnap = try await userDoc.collection("fcmTokens").getDocuments()
        if !tokensSnap.isEmpty {
            let tokenPaths = tokensSnap.documents.map { $0.reference.path }
            try await dataManager.batchDelete(paths: tokenPaths)
        }
        try await dataManager.delete(path: userDoc.path)
    }

    /// Firebase Auth 사용자 삭제 및 오류 핸들링
    @discardableResult
    private func deleteAuth(user: User) async -> Bool {
        do {
            try await user.delete()
            return true
        } catch {
            let nsError = error as NSError
            if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                print("[회원탈퇴] requiresRecentLogin: 최근 로그인 후 다시 시도 필요")
            } else {
                print("[회원탈퇴] Auth 삭제 중 오류: \(nsError.localizedDescription)")
            }
            await MainActor.run {
                self.showWithdrawErrorAlert = true
                self.alertMessage = "탈퇴 중 오류가 생겼습니다. 다시 시도해주세요."
            }
            return false
        }
    }
    
    /// Firestorage URL 판별
    private func isFirebaseStorageURL(_ s: String) -> Bool {
        s.hasPrefix("https://firebasestorage.googleapis.com") || s.hasPrefix("gs://")
    }

    /// 임의 딕셔너리/배열 구조에서 Firebase Storage URL을 수집
    private func collectStorageURLs(from any: Any, into result: inout [String]) {
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
}
