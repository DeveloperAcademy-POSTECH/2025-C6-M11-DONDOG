//
//  EditProfileViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/11/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class EditProfileViewModel: ObservableObject {
    typealias Role = ProfileSetupViewModel.Role
    @Published var name: String = ""
    @Published var selectedRole: Role = .parent

    @Published var errorMessage: String?
    @Published var saveCompleted: Bool = false    // 저장 완료 플래그
    @Published private(set) var didChangeFromInitial: Bool = false

    private let db = Firestore.firestore()
    private var initialName: String = ""
    private var initialRole: Role = .parent

    // 유효성 검사: 공백/개행 제거 후 비어있지 않아야 함
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Public APIs
    func fetchCurrentProfile() {
        errorMessage = nil

        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "로그인 상태가 아닙니다. 다시 로그인해 주세요."
            return
        }

        let docRef = db.collection("Users").document(uid)
        docRef.getDocument { [weak self] snap, err in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let err = err {
                    self.errorMessage = "프로필 정보를 불러오지 못했습니다. (\(err.localizedDescription))"
                    return
                }
                guard let data = snap?.data(), let snap = snap, snap.exists else {
                    self.errorMessage = "프로필 정보가 없습니다. 먼저 프로필을 생성해 주세요."
                    return
                }

                let loadedName = (data["name"] as? String) ?? ""
                let loadedRoleRaw = (data["role"] as? String) ?? "parent"
                let loadedRole = Role(rawValue: loadedRoleRaw) ?? .parent

                self.name = loadedName
                self.selectedRole = loadedRole

                self.initialName = loadedName
                self.initialRole = loadedRole
                self.checkIfModified()
            }
        }
    }

    func saveChanges() {
        errorMessage = nil

        guard isValid else {
            errorMessage = "닉네임을 입력해 주세요."
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "로그인 상태가 아닙니다. 다시 로그인해 주세요."
            return
        }

        let userDoc = db.collection("Users").document(uid)
        userDoc.setData([
            "name": name,
            "role": selectedRole.rawForDB,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { [weak self] err in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let err = err {
                    self.errorMessage = "저장에 실패했습니다. 잠시 후 다시 시도해 주세요. (\(err.localizedDescription))"
                    return
                }

                self.initialName = self.name
                self.initialRole = self.selectedRole
                self.checkIfModified()

                self.saveCompleted = true
            }
        }
    }

    // MARK: - Helpers

    func checkIfModified() {
        didChangeFromInitial = (name != initialName) || (selectedRole != initialRole)
    }
}
