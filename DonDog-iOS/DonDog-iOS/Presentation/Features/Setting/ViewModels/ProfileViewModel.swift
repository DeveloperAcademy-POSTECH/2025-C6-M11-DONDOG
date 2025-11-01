//
//  ProfileViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/9/25.
//

import SwiftUI
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewModel: ObservableObject {
    enum Role: String, CaseIterable {
        case parent
        case child

        var displayIcon: String { self == .parent ? "👵🏻" : "👧🏻" }
        var displayName: String { self == .parent ? "부모님" : "자녀" }
        var rawForDB: String { self.rawValue }
    }

    let mode: ProfileFormMode

    @Published var name: String = ""
    @Published var selectedRole: Role? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var saveCompleted: Bool = false

    // edit 모드 - 버튼 활성화용
    @Published private(set) var didChangeFromInitial: Bool = false
    private var initialName: String = ""
    private var initialRole: Role? = nil

    var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && selectedRole != nil && !isLoading
    }

    var isButtonEnabled: Bool {
        switch mode {
        case .setup:
            return isValid && name.count < 10
        case .edit:
            let nameOK = name.count <= 10
            return ( (!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || didChangeFromInitial ) && nameOK && !isLoading
        }
    }

    private let db = Firestore.firestore()
    private let generateInviteCodeService: GenerateCodeService
    private weak var coordinator: AppCoordinator?

    init(mode: ProfileFormMode,
         generateInviteCodeService: GenerateCodeService = GenerateCodeService(),
         coordinator: AppCoordinator? = nil) {
        self.mode = mode
        self.generateInviteCodeService = generateInviteCodeService
        self.coordinator = coordinator
    }

    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    @MainActor
    func onAppearIfNeeded() async {
        guard mode == .edit else { return }
        await fetchCurrentProfile()
    }

    func save() {
        errorMessage = nil
        switch mode {
        case .setup:
            saveForSetup()
        case .edit:
            saveForEdit()
        }
    }

    private func saveForSetup() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "로그인 상태가 아닙니다. 다시 시도해 주세요."
            return
        }
        isLoading = true

        generateInviteCodeService.generateUniqueInviteCode { [weak self] result in
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
        let userDocument = db.collection("Users").document(uid)
        let inviteDocument = db.collection("Invites").document(inviteCode)
        let batch = db.batch()

        // Users/{uid}
        batch.setData([
            "name": self.name,
            "role": (self.selectedRole?.rawForDB ?? ""),
            "recentPostId": "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: userDocument, merge: true)

        // Invites/{inviteCode}
        let expireDate = Timestamp(date: Date().addingTimeInterval(24 * 60 * 60))
        batch.setData([
            "inviterUid": uid,
            "expireDate": expireDate
        ], forDocument: inviteDocument, merge: false)

        batch.commit { [weak self] commitError in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let commitError = commitError {
                    self.errorMessage = "프로필 저장에 문제가 발생했습니다. 잠시 후 다시 시도해주세요. (\(commitError.localizedDescription))"
                    self.isLoading = false
                } else {
                    self.isLoading = false
                    self.saveCompleted = true
                    self.coordinator?.inviteShowSentHint = true
                    self.coordinator?.replaceRoot(.invite)
                }
            }
        }
    }

    @MainActor
    private func fetchCurrentProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "로그인 상태가 아닙니다. 다시 로그인해 주세요."
            return
        }
        do {
            let snap = try await db.collection("Users").document(uid).getDocument()
            guard let data = snap.data(), snap.exists else {
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
        } catch {
            self.errorMessage = "프로필 정보를 불러오지 못했습니다. (\(error.localizedDescription))"
        }
    }

    private func saveForEdit() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "닉네임을 입력해 주세요."
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "로그인 상태가 아닙니다. 다시 로그인해주세요"
            return
        }

        isLoading = true
        db.collection("Users").document(uid).setData([
            "name": name,
            "role": (selectedRole?.rawForDB ?? ""),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { [weak self] err in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
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
    private func checkIfModified() {
        didChangeFromInitial = (name != initialName) || (selectedRole != initialRole)
    }
}
