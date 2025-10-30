//
//  InviteViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class InviteViewModel: ObservableObject {
    @Published var userName: String?
    @Published var inviteCode: String?
    @Published var expireDate: Date?
    @Published var inviteText: String = ""
    @Published var remainTimeText: String = ""
    @Published var inputInviteCode: String = ""
    @Published var connectSucceeded: Bool = false
    @Published var message: String = ""
    @Published var isLoading: Bool = false
    @Published var allowInviteCodeError: Bool = false
    
    @Published var showSentHint: Bool = false
    
    private let db = Firestore.firestore()
    private let dataManager: DataManagerProtocol = DataManager.shared
    private let generateInviteCodeService: GenerateCodeService
    
    private var timerCancellable: AnyCancellable?
    private var stagedInviteText: String = ""
    
    init(showSentHint: Bool = false, generateInviteCodeService: GenerateCodeService = GenerateCodeService()) {
        self.showSentHint = showSentHint
        self.generateInviteCodeService = generateInviteCodeService
    }
    
    private var currentUserUID: String? {
        guard let uid = dataManager.getCurrentUserId() else {
            self.inviteText = "로그인이 필요합니다"
            self.isLoading = false
            return nil
        }
        return uid
    }
    
    // MARK: - 내 초대코드 띄우기
    func fetchInviteCodeandExpireDate() {
        guard let uid = currentUserUID else { return }
        self.isLoading = true
        
        Task { [weak self] in
            guard let self = self,
                  let user: UserData = try? await self.dataManager.fetch(path: "Users/\(uid)") else { return }
            await MainActor.run { self.userName = user.name }
        }
        
        db.collection("Invites").whereField("inviterUid", isEqualTo: uid).getDocuments { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let document = result?.documents.first {
                    self.inviteCode = document.documentID
                    
                    if let lefttime = document.data()["expireDate"] as? Timestamp {
                        self.expireDate = lefttime.dateValue()
                    } else {
                        self.expireDate = nil
                    }
                    self.stagedInviteText = "\(self.inviteCode ?? "")"
                    self.inviteText = ""
                    self.startTimer()
                } else {
                    self.inviteText = "초대코드를 불러오지 못했습니다."
                }
                self.isLoading = false
            }
        }
    }
    
    private func startTimer() {
        timerCancellable?.cancel()
        guard let expireDate = expireDate else {
            remainTimeText = ""
            return
        }
        remainTimeText = ""
        inviteText = ""
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let remaining = expireDate.timeIntervalSinceNow
                if remaining > 0 {
                    if self.inviteText.isEmpty {
                        self.inviteText = self.stagedInviteText
                    }
                    self.remainTimeText = "\(InviteViewModel.timeFormat(remaining))"
                } else {
                    self.remainTimeText = "00:00"
                    self.inviteText = "코드가 만료되었어요"
                    self.timerCancellable?.cancel()
                }
            }
    }
    
    static func timeFormat(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }
    
    // MARK: - 다른 사람 초대코드 입력
    func connectWithInviteCode() {
        message = ""
        connectSucceeded = false
        isLoading = true
        allowInviteCodeError = false
        
        let inputcode = inputInviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !inputcode.isEmpty else {
            message = "초대 코드를 입력해 주세요."
            self.allowInviteCodeError = true
            isLoading = false
            return
        }
        
        if inputcode == inviteCode {
            message = "초대 코드를 다시 확인해 주세요."
            self.allowInviteCodeError = true
            isLoading = false
            return
        }

        Task { [weak self] in
            guard let self = self else { return }
            do {
                /// 초대코드가 db에 있는지 찾음
                let invitedoc: InviteDoc = try await dataManager.fetch(path: "Invites/\(inputcode)")
                /// 만료 시간 확인
                if let ts = invitedoc.expireDate, ts.dateValue() < Date() {
                    await MainActor.run {
                        self.message = "유효하지 않은 초대코드입니다."
                        self.allowInviteCodeError = true
                        self.isLoading = false
                    }
                    return
                }
                /// 초대자 uid 확인
                let inviterUid = invitedoc.inviterUid
                let inviterUser: UserData = try await self.dataManager.fetch(path: "Users/\(inviterUid)")
                guard let myUid = self.currentUserUID else { return }
                let myUserDoc = self.db.collection("Users").document(myUid)
                let inviterUserDoc = self.db.collection("Users").document(inviterUid)
                
                /// A) 초대자의 유저 문서에 roomId가 있는 경우 → 기존 방에 내 uid를 참가자로 추가하고, 내 Users 문서에 roomId/createdAt 저장
                if let inviterRoomId = inviterUser.roomId, !inviterRoomId.isEmpty {
                    let roomDoc = self.db.collection("Rooms").document(inviterRoomId)
                    do {
                        try await self.commitRoomJoin(
                            roomDoc: roomDoc,
                            myUserDoc: myUserDoc,
                            inviterUserDoc: inviterUserDoc,
                            roomId: inviterRoomId,
                            participantUids: [myUid]
                        )
                        await MainActor.run {
                            self.isLoading = false
                            self.connectSucceeded = true
                        }
                    } catch {
                        await MainActor.run {
                            self.message = "유효하지 않은 초대코드입니다. \(error.localizedDescription)"
                            self.allowInviteCodeError = true
                            self.isLoading = false
                        }
                    }
                } else {
                    /// B) 초대자의 유저 문서에 roomId가 없는 경우 → 고유 roomId 생성 → Rooms 생성 → participants에 초대자/나 모두 추가 → 두 사용자 문서에 roomId/createdAt 저장
                    func attemptGenerateUniqueRoomIdAndSave() async {
                        while true {
                            let candidate = UUID().uuidString
                            let roomDoc = await self.db.collection("Rooms").document(candidate)
                            do {
                                let snap = try await roomDoc.getDocument()
                                if snap.exists {
                                    continue
                                }
                                try await self.commitRoomJoin(
                                    roomDoc: roomDoc,
                                    myUserDoc: myUserDoc,
                                    inviterUserDoc: inviterUserDoc,
                                    roomId: candidate,
                                    participantUids: [inviterUid, myUid]
                                )
                                await MainActor.run {
                                    self.isLoading = false
                                    self.connectSucceeded = true
                                }
                                break
                            } catch {
                                await MainActor.run {
                                    self.message = "문제가 생겼어요. 잠시 후 다시 시도해 주세요. \(error.localizedDescription)"
                                    self.allowInviteCodeError = true
                                    self.isLoading = false
                                }
                                return
                            }
                        }
                    }
                    Task {
                        await attemptGenerateUniqueRoomIdAndSave()
                    }
                }
            }
        }
    }
    
    private func commitRoomJoin(
        roomDoc: DocumentReference,
        myUserDoc: DocumentReference,
        inviterUserDoc: DocumentReference?,
        roomId: String,
        participantUids: [String]
    ) async throws {
        let roomPath = roomDoc.path
        let myUserPath = myUserDoc.path

        var ops: [DataManager.BatchOption] = []

        if participantUids.count == 1 {
            // A) 기존 방: participants에 내 uid만 추가 (덮어쓰기 금지)
            ops.append(.update(path: roomPath, data: [
                "participants": FieldValue.arrayUnion(participantUids)
            ]))
        } else {
            // B) 새 방: 두 명으로 설정 + createdAt 기록
            ops.append(.upsert(path: roomPath, data: [
                "participants": participantUids,
                "createdAt": FieldValue.serverTimestamp()
            ]))
        }
        // 초대자 유저 문서는 B 케이스에서만 업서트
        if participantUids.count > 1, let inviterPath = inviterUserDoc?.path {
            ops.append(.upsert(path: inviterPath, data: [
                "roomId": roomId,
                "updatedAt": FieldValue.serverTimestamp()
            ]))
        }
        
        // 내 유저 문서 roomId 업서트
        ops.append(.upsert(path: myUserPath, data: [
            "roomId": roomId,
            "updatedAt": FieldValue.serverTimestamp()
        ]))

        try await dataManager.batchUpdate(ops)
    }
    
    // MARK: - 내 초대코드 재생성
    func refreshInviteCode() {
        self.isLoading = true
        guard let uid = dataManager.getCurrentUserId() else {
            self.isLoading = false
            return
        }
        
        func createNewInvite() {
            generateInviteCodeService.generateUniqueInviteCode { result in
                switch result {
                case .failure(_):
                    self.isLoading = false
                    
                case .success(let newCode):
                    let expireDate = Date().addingTimeInterval(24 * 60 * 60)
                    let inviteDoc = self.db.collection("Invites").document(newCode)
                    inviteDoc.setData([
                        "inviterUid": uid,
                        "expireDate": expireDate
                    ]) { error in
                        if error != nil {
                            self.isLoading = false
                            return
                        }
                        self.inviteCode = newCode
                        self.stagedInviteText = newCode
                        self.expireDate = expireDate
                        self.inviteText = ""
                        self.startTimer()
                    }
                }
            }
        }
        
        if let oldCode = inviteCode, !oldCode.isEmpty {
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    try await self.dataManager.delete(path: "Invites/\(oldCode)")
                    createNewInvite()
                } catch {
                    await MainActor.run {
                        self.inviteText = "다시 시도해주세요"
                        self.isLoading = false
                    }
                }
            }
        } else {
            createNewInvite()
        }
    }
}
