//
//  ProfileSetupViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/4/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class ProfileSetupViewModel: ObservableObject {
    enum Role: String, CaseIterable {
        case parent
        case child

        var displayName: String { self == .parent ? "부모" : "자녀" }
        var rawForDB: String { self.rawValue }
    }

    @Published var name: String = ""
    @Published var selectedRole: Role = .parent
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var didComplete: Bool = false
    private let inviteCodeService = InviteCodeService()

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    
    private let db = Firestore.firestore()

    func saveUserProfile() {
        errorMessage = nil
        
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "로그인 상태가 아닙니다. 다시 시도해 주세요."
            return
        }

        isLoading = true

        // 1) 유니크 초대코드 생성 → 2) Users/{uid}, Invites/{inviteCode} 저장
        inviteCodeService.generateUniqueInviteCode { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                DispatchQueue.main.async {
                    self.errorMessage = "설정 저장 중 오류가 발생했습니다: \(err.localizedDescription)"
                    self.isLoading = false
                }
            case .success(let inviteCode):
                self.saveProfile(inviteCode: inviteCode, uid: uid)
            }
        }
    }
    
    private func saveProfile(inviteCode: String, uid: String) {
        let userDocument = self.db.collection("Users").document(uid)
        let inviteDocument = self.db.collection("Invites").document(inviteCode)
        let saveTogether = self.db.batch()

        // 사용자 정보 (Users/{uid})
        saveTogether.setData([
            "name": self.name,
            "role": self.selectedRole.rawForDB,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "recentSticker": ""
        ], forDocument: userDocument, merge: true)

        // 초대코드 정보 (Invites/{inviteCode})
        let expireDate = Timestamp(date: Date().addingTimeInterval(24 * 60 * 60))
        saveTogether.setData([
            "inviterUid": uid,
            "expireDate": expireDate
        ], forDocument: inviteDocument, merge: false)

        // 한 번에 저장(commit)
        saveTogether.commit { commitError in
            DispatchQueue.main.async {
                if let commitError = commitError {
                    self.errorMessage = "프로필 저장에 문제가 발생했습니다. 잠시 후 다시 시도해주세요. (\(commitError.localizedDescription))"
                    self.isLoading = false
                } else {
                    self.isLoading = false
                    self.didComplete = true
                }
            }
        }
    }
}
