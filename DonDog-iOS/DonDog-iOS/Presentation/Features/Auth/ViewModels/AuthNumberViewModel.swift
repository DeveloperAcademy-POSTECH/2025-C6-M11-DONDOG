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
    @Published var showAlert = false
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
                } else {
                    self.codeError = nil
                    print("인증 성공")
                    if let user = Auth.auth().currentUser {
                        print("전화번호:", user.phoneNumber ?? "없음")
                    }
                    if self.isNumberWithdraw == true {
                        print("탈퇴 시작")
                        self.performAccountDeletion()
                    } else {
                        print("로그인 성공")
                        self.routeAfterSignIn()
                    }
                }
                self.isLoading = false
            }
        }
    }
    
    private func performAccountDeletion() {
        Task {
            await deleteUserDataAndAuth()
        }
    }
    
    private func deleteUserDataAndAuth() async {
        guard let user = Auth.auth().currentUser else {
            print("[회원탈퇴] 로그인 정보를 찾을 수 없습니다")
            return
        }
        
        await MainActor.run {
            AuthService.isAccountDeletionInProgress = true
        }

        let uid = user.uid
        let db = Firestore.firestore()

        do {
            // 1) Firestore 정리
            // Users/{uid}를 읽어 roomId 등을 확인
            let userDoc = db.collection("Users").document(uid)
            let userData = try await userDoc.getDocument()
            var roomId: String? = nil
            if let data = userData.data(), let rid = data["roomId"] as? String, !rid.isEmpty {
                roomId = rid
            }

            let deleteTgt = db.batch()

            // Users/{uid} 삭제
            deleteTgt.deleteDocument(userDoc)

            // Invites 에서 uid가 있는 문서 삭제
            let invitesDoc = db.collection("Invites")
            let inviterQuery = invitesDoc.whereField("inviterUid", isEqualTo: uid)
            let inviterData = try await inviterQuery.getDocuments()
            for doc in inviterData.documents {
                deleteTgt.deleteDocument(doc.reference)
            }

            // Rooms
            // participants에서 제거, 비면 방 삭제
            // (Users/{uid}.roomId 필드 기반 우선 처리 + 방어적으로 participants 검색)
            var roomDocToCheck: [DocumentReference] = []
            if let rid = roomId, !rid.isEmpty {
                roomDocToCheck.append(db.collection("Rooms").document(rid))
            }
            // participants 배열에 내 uid가 포함된 모든 방을 역으로 검색
            let roomsDoc = db.collection("Rooms").whereField("participants", arrayContains: uid)
            let roomData = try await roomsDoc.getDocuments()
            roomDocToCheck.append(contentsOf: roomData.documents.map { $0.reference })

            // 중복된 후보 제거
            var uniqueRids = [String: DocumentReference]()
            for ref in roomDocToCheck {
                uniqueRids[ref.path] = ref
            }

            // Users/Invites clean-up in a batch, but do NOT include Rooms participants update in that batch
            try await deleteTgt.commit()

            // participants에서 uid 제거 (존재하는 방에 한해 개별 업데이트)
            for (_, ref) in uniqueRids {
                do {
                    try await ref.updateData(["participants": FieldValue.arrayRemove([uid])])
                } catch {
                    let ns = error as NSError
                    if ns.domain == FirestoreErrorDomain,
                       FirestoreErrorCode.Code(rawValue: ns.code) == .notFound {
                        // 방이 이미 삭제된 경우: 무시하고 계속 진행
                        continue
                    } else {
                        throw error
                    }
                }
            }

            // participants 제거 후 빈 방이면 삭제 방 삭제, 방 내부의 storage 파일 삭제
            for (_, ref) in uniqueRids {
                let snap = try await ref.getDocument()
                if let data = snap.data(), let parts = data["participants"] as? [String], parts.isEmpty {
                    let storage = Storage.storage()
                    let postsDoc = try await ref.collection("posts").getDocuments()

                    func isFirebaseStorageURL(_ s: String) -> Bool {
                        return s.hasPrefix("https://firebasestorage.googleapis.com")
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

                    // 2) 모든 Storage URL 동적 수집 후 삭제
                    var urlsToDelete: [String] = []
                    for doc in postsDoc.documents {
                        let data = doc.data()
                        collectStorageURLs(from: data, into: &urlsToDelete)
                    }
                    // 중복 제거
                    urlsToDelete = Array(Set(urlsToDelete))

                    try await withThrowingTaskGroup(of: Void.self) { group in
                        for url in urlsToDelete {
                            group.addTask {
                                try await storage.reference(forURL: url).delete()
                            }
                        }
                        try await group.waitForAll()
                    }

                    // 3) posts 문서 삭제 (배치)
                    if !postsDoc.isEmpty {
                        let deleteTgt = db.batch()
                        postsDoc.documents.forEach { deleteTgt.deleteDocument($0.reference) }
                        try await deleteTgt.commit()
                    }

                    // 4) 마지막으로 Rooms/{roomId} 문서 삭제
                    try await ref.delete()
                }
            }
            
            // 2) Firebase Auth 사용자 삭제
            do {
                try await user.delete()
                await MainActor.run {
                    AuthService.isAccountDeletionInProgress = false
                    self.coordinator?.replaceRoot(.welcome)
                }
            } catch {
                let nsError = error as NSError
                await MainActor.run {
                    AuthService.isAccountDeletionInProgress = false
                }
                if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    print("[회원탈퇴] requiresRecentLogin: 최근 로그인 후 다시 시도 필요")
                    await MainActor.run {
                        self.showAlert = true
                        self.alertMessage = "탈퇴 중 오류가 생겼습니다. 다시 시도해주세요."
                    }
                } else {
                    print("[회원탈퇴] Auth 삭제 중 오류: \(nsError.localizedDescription)")
                    await MainActor.run {
                        self.showAlert = true
                        self.alertMessage = "탈퇴 중 오류가 생겼습니다. 다시 시도해주세요."
                    }
                }
                return
            }
        } catch {
            let nsError = error as NSError
            print("[회원탈퇴] 오류: \(nsError.localizedDescription)")
            await MainActor.run {
                self.showAlert = true
                self.alertMessage = "탈퇴 중 오류가 생겼습니다. 다시 시도해주세요."
            }
        }
    }
    
    private func routeAfterSignIn() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("Users").document(uid)

        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("[Auth][routeAfterSignIn] fetch user doc error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.coordinator?.push(.profileSetup)
                }
                return
            }

            let exists = (snapshot?.exists == true)
            DispatchQueue.main.async {
                if exists {
                    self.coordinator?.replaceRoot(.feed)
                    self.isLoading = false
                } else {
                    self.coordinator?.replaceRoot(.profileSetup)
                    self.isLoading = false
                }
            }
        }
    }
    
}
