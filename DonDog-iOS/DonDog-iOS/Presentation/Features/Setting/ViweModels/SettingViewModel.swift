//
//  SettingViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/9/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class SettingViewModel: ObservableObject {
    @Published var showLogoutConfirm = false
    @Published var showDeleteConfirm = false
    @Published var isDeleting = false
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }
    
    func performAccountDeletion() {
        isDeleting = true
        Task {
            await deleteUserDataAndAuth()
        }
    }
    
    func deleteUserDataAndAuth() async {
        guard let user = Auth.auth().currentUser else {
            print("[회원탈퇴] 로그인 정보를 찾을 수 없습니다")
            return
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

            // participants에서 uid 제거
            for (_, ref) in uniqueRids {
                deleteTgt.updateData(["participants": FieldValue.arrayRemove([uid])], forDocument: ref)
            }

            // 배치 커밋 (users/ invites/ rooms arrayRemove 까지)
            try await deleteTgt.commit()

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
                print("유저 삭제를 위해 다시 전화번호 인증")
                // 다시 인증받기
                try await user.delete()
            } catch {
                let nsError = error as NSError
                if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    print("[회원탈퇴] requiresRecentLogin: 최근 로그인 후 다시 시도 필요")
                    // 유저 안내 필요 (다시 로그인 시도)
                } else {
                    print("[회원탈퇴] Auth 삭제 중 오류: \(nsError.localizedDescription)")
                    // 유저 안내 필요
                }
            }
        } catch {
            let nsError = error as NSError
            print("[회원탈퇴] 오류: \(nsError.localizedDescription)")
            // 유저 안내 필요
        }

        await MainActor.run {
            isDeleting = false
        }
    }
}
