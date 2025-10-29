//
//  CardTextViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/29/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class CardTextViewModel: ObservableObject {
    // TODO: User 싱글톤 사용
    @Published var name: String = "익명"
    
    init() {
        fetchUserName()
    }
    
    func fetchUserName() {
        guard let currentUser = Auth.auth().currentUser else {
            print("사용자 정보가 잘못되었습니다.")
            return
        }
        
        let currentUserId = currentUser.uid
        Firestore.firestore()
            .collection("Users")
            .document(currentUserId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("사용자 이름 가져오지 못했습니다: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let name = data["name"] as? String {
                    self.name = name
                } else {
                    print("사용자 이름이 존재하지 않습니다.")
                    self.name = "익명"
                }
            }
    }
}
