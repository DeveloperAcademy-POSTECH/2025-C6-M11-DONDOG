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
            print("[Delete] 로그인 상태가 아닙니다.")
            return
        }
        
        let uid = user.uid
        let db = Firestore.firestore()

        do {
            // 1) Firestore 정리
            // Users/{uid} 문서의 현재 상태를 읽어 roomId 등을 확인
            let userDoc = db.collection("Users").document(uid)
            let userData = try await userDoc.getDocument()
            var roomId: String? = nil
            
            if let data = userData.data(), let rid = data["roomId"] as? String, !rid.isEmpty {
                roomId = rid
            }

            let deleteTgt = db.batch()
            
            // Users/{uid} 삭제
            deleteTgt.deleteDocument(userDoc)

            // Invites 에서 내 uid가 있던 문서 삭제
            let invitesDoc = db.collection("Invites")
            let inviterQuery = invitesDoc.whereField("inviterUid", isEqualTo: uid)
            let inviterSnaps = try await inviterQuery.getDocuments()
            for doc in inviterSnaps.documents {
                deleteTgt.deleteDocument(doc.reference)
            }

            // 이 밑부터 재검사
            // Rooms 에서 나를 participants에서 제거, 비면 방 삭제
            // (Users/{uid}.roomId 필드 기반 우선 처리 + 방어적으로 participants 검색)
            var roomRefsToCheck: [DocumentReference] = []
            if let rid = roomId, !rid.isEmpty {
                roomRefsToCheck.append(db.collection("Rooms").document(rid))
            }
            let roomsQuery = db.collection("Rooms").whereField("participants", arrayContains: uid)
            let roomsSnaps = try await roomsQuery.getDocuments()
            roomRefsToCheck.append(contentsOf: roomsSnaps.documents.map { $0.reference })

            // 중복 제거
            var uniqueRefs = [String: DocumentReference]()
            for ref in roomRefsToCheck {
                uniqueRefs[ref.path] = ref
            }

            // participants에서 uid 제거 (배치로는 arrayRemove 직접 불가하므로 업데이트 배치는 개별 수행)
            // 먼저 arrayRemove 적용
            for (_, ref) in uniqueRefs {
                deleteTgt.updateData(["participants": FieldValue.arrayRemove([uid])], forDocument: ref)
            }

            // 배치 커밋 (users/ invites/ rooms arrayRemove 까지)
            try await deleteTgt.commit()

            // participants 제거 후 빈 방이면 삭제
            for (_, ref) in uniqueRefs {
                let snap = try await ref.getDocument()
                if let data = snap.data(), let parts = data["participants"] as? [String], parts.isEmpty {
                    try await ref.delete()
                }
            }

            // 2) Firebase Auth 사용자 삭제
            do {
                try await user.delete()
            } catch {
                let nsError = error as NSError
                if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    print("[Delete] requiresRecentLogin: 최근 로그인 후 다시 시도 필요")
                } else {
                    print("[Delete] Auth 삭제 중 오류: \(nsError.localizedDescription)")
                }
            }
        } catch {
            let nsError = error as NSError
            print("[Delete] 데이터 삭제 중 오류: \(nsError.localizedDescription)")
        }

        await MainActor.run {
            isDeleting = false
        }
    }
}
