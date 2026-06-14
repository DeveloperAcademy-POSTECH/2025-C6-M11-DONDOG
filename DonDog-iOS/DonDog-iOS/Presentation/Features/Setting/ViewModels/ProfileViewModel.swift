//
//  ProfileViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/9/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

final class ProfileViewModel: ObservableObject {
    enum Role: String, CaseIterable {
        case parent
        case child
        
        var iconOffName: String {
            switch self {
                case .parent: return "ParentIconOff"
                case .child:  return "ChildIconOff"
                }
            }
        var iconOnName: String {
            switch self {
            case .parent: return "ParentIconOn"
            case .child:  return "ChildIconOn"
            }
        }

        var displayName: String { self == .parent ? "부모님" : "자녀" }
        var rawForDB: String { self.rawValue }
    }

    let mode: ProfileFormMode
    private let connectUserInfo = UserPairingStore.shared
    private let dataManager: DataManagerProtocol = DataManager.shared

    @Published var name: String = "" { didSet { checkIfModified() } }
    @Published var selectedRole: Role? { didSet { checkIfModified() } }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var saveCompleted: Bool = false

    // edit 모드 - 버튼 활성화용
    @Published private(set) var didChangeFromInitial: Bool = false
    @Published private(set) var didChangeRole: Bool = false
    private var initialName: String = ""
    private var initialRole: Role?
    private var myUid: String? {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "로그인 상태가 아닙니다. 다시 시도해 주세요."
            return nil
        }
        return uid
    }
    
    var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && selectedRole != nil && !isLoading
    }

    var isButtonEnabled: Bool {
        switch mode {
        case .setup:
            return isValid && name.count < 10
        case .edit:
            let nameLength = name.count <= 10
            return ( (!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || didChangeFromInitial) && nameLength && !isLoading
        }
    }

    private let generateInviteCodeService: GenerateCodeService
    private weak var coordinator: AppCoordinator?

    init(mode: ProfileFormMode, generateInviteCodeService: GenerateCodeService = GenerateCodeService(), coordinator: AppCoordinator? = nil) {
        self.mode = mode
        self.generateInviteCodeService = generateInviteCodeService
        self.coordinator = coordinator
    }

    func attach(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

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

    func saveWithStickerReset() {
        errorMessage = nil

        guard mode == .edit else {
            save()
            return
        }

        guard let uid = myUid else { return }
        isLoading = true
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                guard let manager = self.dataManager as? DataManager else {
                    self.errorMessage = "데이터 매니저를 찾을 수 없습니다. 잠시 후 다시 시도해 주세요."
                    self.isLoading = false
                    return
                }
                try await manager.deleteWhereEqual(
                    path: "Stickers",
                    field: "authorUid",
                    isEqualTo: uid
                )
                self.saveForEdit()
            } catch {
                self.errorMessage = "스티커 초기화 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요. (\(error.localizedDescription))"
                self.isLoading = false
            }
        }
        
        StickerGridService.shared.deleteCache()
    }

    private func saveForSetup() {
        guard let myUid = myUid else { return }
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
                self.saveProfile(inviteCode: inviteCode, myUid: myUid)
            }
        }
    }

    private func saveProfile(inviteCode: String, myUid: String) {
        isLoading = true
        let userPath = "Users/\(myUid)"
        let invitePath = "Invites/\(inviteCode)"
        let expireDate = Timestamp(date: Date().addingTimeInterval(24 * 60 * 60))

        let options: [DataManager.BatchOption] = [
            .upsert(path: userPath, data: [
                "name": self.name,
                "role": (self.selectedRole?.rawForDB ?? ""),
                "recentPostId": "",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]),
            .upsert(path: invitePath, data: [
                "inviterUid": myUid,
                "expireDate": expireDate
            ])
        ]

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.dataManager.batchUpdate(options)
                self.isLoading = false
                self.saveCompleted = true
                self.coordinator?.inviteShowSentHint = true
                self.coordinator?.replaceRoot(.invite)
            } catch {
                self.errorMessage = "프로필 저장에 문제가 발생했습니다. 잠시 후 다시 시도해주세요. (\(error.localizedDescription))"
                self.isLoading = false
            }
        }
    }

    private func fetchCurrentProfile() async {
        if let myName = connectUserInfo.myName {
            self.name = myName
        }
        if let myRoleRaw = connectUserInfo.myRole, let role = Role(rawValue: myRoleRaw) {
            self.selectedRole = role
        }
        self.initialName = self.name
        self.initialRole = self.selectedRole
        self.checkIfModified()
        return
    }

    private func saveForEdit() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "닉네임을 입력해 주세요."
            return
        }
        guard let myUid = myUid else { return }

        isLoading = true
        let userPath = "Users/\(myUid)"
        let updateData: [String: Any] = [
            "name": name,
            "role": (selectedRole?.rawForDB ?? ""),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.dataManager.update(path: userPath, data: updateData)
                self.isLoading = false
                self.initialName = self.name
                self.initialRole = self.selectedRole
                self.checkIfModified()
                self.saveCompleted = true
            } catch {
                self.errorMessage = "저장에 실패했습니다. 잠시 후 다시 시도해 주세요. (\(error.localizedDescription))"
                self.isLoading = false
            }
        }
    }

    private func checkIfModified() {
        didChangeFromInitial = (name != initialName) || (selectedRole != initialRole)
        didChangeRole = (selectedRole != initialRole)
    }
}
