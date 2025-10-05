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
    
    private let db = Firestore.firestore()
    private var timerCancellable: AnyCancellable?
    
    func fetchInviteCodeandExpireDate() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Invites").whereField("inviterUid", isEqualTo: uid).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let document = snapshot?.documents.first {
                    self.inviteCode = document.documentID
                    
                    if let lefttime = document.data()["expireDate"] as? Timestamp {
                        self.expireDate = lefttime.dateValue()
                    } else {
                        self.expireDate = nil
                    }
                    
                    self.inviteText = "초대코드: \(self.inviteCode ?? "")"
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
    
}
