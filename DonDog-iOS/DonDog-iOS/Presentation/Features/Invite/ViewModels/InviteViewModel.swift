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
    @Published var inviteCode: String?
    @Published var expireDate: Date?
    @Published var inviteText: String = ""
    @Published var remainTimeText: String = ""
    @Published var inputInviteCode: String = ""
    @Published var connectSucceeded: Bool = false
    @Published var connectMessage: String = ""
    
    private let db = Firestore.firestore()
    private var timerCancellable: AnyCancellable?
    
    // MARK: - 내 초대코드 띄우기
    func fetchInviteCodeandExpireDate() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
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
                    
                    self.inviteText = "\(self.inviteCode ?? "")"
                    self.startTimer()
                } else {
                    self.inviteText = "초대코드를 불러오지 못했습니다."
                }
            }
        }
    }
    
    private func startTimer() {
        timerCancellable?.cancel()
        guard let expireDate = expireDate else {
            remainTimeText = ""
            return
        }
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let remaining = expireDate.timeIntervalSinceNow
                if remaining > 0 {
                    self.remainTimeText = "잔여 시간 \(InviteViewModel.timeFormat(remaining))"
                } else {
                    self.remainTimeText = "만료됨"
                    self.timerCancellable?.cancel()
                }
            }
    }
    
    static func timeFormat(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
    
    // MARK: - 다른 사람 초대코드 입력
    func connectWithInviteCode() {
        connectMessage = ""
        connectSucceeded = false
        
        let inputcode = inputInviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inputcode.isEmpty else {
            connectMessage = "초대코드를 입력해 주세요."
            return
        }

        let inviteDoc = db.collection("Invites").document(inputcode)
        inviteDoc.getDocument { [weak self] result, error in
            guard let self = self else { return }
            /// 초대코드가 db에 있는지 찾음
            if let error = error {
                DispatchQueue.main.async { self.connectMessage = "초대코드 조회 실패: \(error.localizedDescription)" }
                return
            }
            guard let doc = result, doc.exists else {
                DispatchQueue.main.async { self.connectMessage = "유효하지 않은 초대코드입니다." }
                return
            }
            /// 찾은 후 문서 내 데이터를 딕셔너리 형태로 가져온 후, expireDate 확인
            //:: 수정?
            let inviteData = doc.data() ?? [:]
            if let expireDateFromDoc = inviteData["expireDate"] as? Timestamp {
                let expire = expireDateFromDoc.dateValue()
                if expire < Date() {
                    DispatchQueue.main.async { self.connectMessage = "초대코드가 만료되었습니다." }
                    return
                }
            }
            /// 초대자의 Uid 확인
            guard let inviterUid = inviteData["inviterUid"] as? String, !inviterUid.isEmpty else {
                DispatchQueue.main.async { self.connectMessage = "초대코드 데이터가 올바르지 않습니다." }
                return
            }
            /// 초대자의 roomId 확인
            let inviterUserDoc = self.db.collection("Users").document(inviterUid)
            inviterUserDoc.getDocument { inviterDoc, inviterErr in
                if let inviterErr = inviterErr {
                    DispatchQueue.main.async { self.connectMessage = "초대자 정보 조회 실패: \(inviterErr.localizedDescription)" }
                    return
                }

                let inviterRoomId = inviterDoc?.data()? ["roomId"] as? String
                // A) 초대자의 유저 문서에 roomId가 있는 경우 → 기존 방에 내 uid를 참가자로 추가하고, 내 Users 문서에 roomId/createdAt 저장
                if let existingRoomId = inviterRoomId, !existingRoomId.isEmpty {
                    let roomDoc = self.db.collection("Rooms").document(existingRoomId)
                    
                    guard let myUid = Auth.auth().currentUser?.uid else {
                        self.connectMessage = "로그인이 필요합니다"
                        return
                    }
                    let myUserDoc = self.db.collection("Users").document(myUid)
                    
                    self.commitRoomJoin(roomDoc: roomDoc, myUserDoc: myUserDoc, inviterUserDoc: nil, roomId: existingRoomId, participantUids: [myUid]) { err in
                        if let err = err {
                            DispatchQueue.main.async { self.connectMessage = "방 연결 실패: \(err.localizedDescription)" }
                            return
                        }
                        DispatchQueue.main.async {
                            self.connectMessage = "방 연결에 성공했습니다."
                            self.connectSucceeded = true
                        }
                    }
                } else {
                    // B) 초대자의 유저 문서에 roomId가 없는 경우 → 고유 roomId 생성 → Rooms 생성 → participants에 초대자/나 모두 추가 → 두 사용자 문서에 roomId/createdAt 저장
                    guard let myUid = Auth.auth().currentUser?.uid else {
                        self.connectMessage = "로그인이 필요합니다"
                        return
                    }

                    func attemptGenerateUniqueRoomIdAndSave() {
                        let candidate = UUID().uuidString
                        let roomDoc = self.db.collection("Rooms").document(candidate)
                        
                        roomDoc.getDocument { doc, err in
                            if let err = err {
                                DispatchQueue.main.async { self.connectMessage = "roomId 생성 실패: \(err.localizedDescription)" }
                                return
                            }
                            if let s = doc, s.exists {
                                attemptGenerateUniqueRoomIdAndSave()
                                return
                            }
                            
                            let myUserDoc = self.db.collection("Users").document(myUid)
                            self.commitRoomJoin(roomDoc: roomDoc, myUserDoc: myUserDoc, inviterUserDoc: inviterUserDoc, roomId: candidate, participantUids: [inviterUid, myUid]) { err in
                                if let err = err {
                                    DispatchQueue.main.async { self.connectMessage = "방 연결 실패: \(err.localizedDescription)" }
                                    return
                                }
                                DispatchQueue.main.async {
                                    self.connectMessage = "방 연결에 성공했습니다."
                                    self.connectSucceeded = true
                                }
                            }
                        }
                    }
                    // 고유 roomId가 확보될 때까지 재시도하며 저장
                    attemptGenerateUniqueRoomIdAndSave()
                }
            }
        }
    }
    
    private func commitRoomJoin(roomDoc: DocumentReference, myUserDoc: DocumentReference, inviterUserDoc: DocumentReference?, roomId: String, participantUids: [String], completion: @escaping (Error?) -> Void) {
        let saveTgt = db.batch()
        // Rooms/{roomId}의 participants에 uid 추가
        saveTgt.setData([
            "participants": participantUids,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: roomDoc, merge: true)
        // 내 유저 문서에 roomId 추가
        saveTgt.setData([
            "roomId": roomId,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: myUserDoc, merge: true)
        // 초대자 유저 문서에 roomId 추가
        if let inviterUserDoc = inviterUserDoc {
            saveTgt.setData([
                "roomId": roomId,
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: inviterUserDoc, merge: true)
        }
        saveTgt.commit(completion: completion)
    }
    
}
