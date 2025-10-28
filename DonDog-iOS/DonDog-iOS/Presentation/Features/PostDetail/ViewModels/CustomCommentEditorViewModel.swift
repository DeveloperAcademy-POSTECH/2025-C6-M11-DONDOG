//
//  CustomCommentEditorViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class CustomCommentEditorViewModel: ObservableObject {
    @Published var name: String = "익명"
    
    init() {
        fetchUserName()
    }
    
    func saveComment() async {
        // TODO: 댓글 저장 로직 구현
    }
    
    func fetchUserName() {
        guard let currentUser = Auth.auth().currentUser else {
            print("현재 사용자 정보를 가져오지 못했습니다.")
            return
        }
        
        Firestore.firestore()
            .collection("Users")
            .document(currentUser.uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("사용자 이름을 가져오지 못했습니다: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let name = data["name"] as? String {
                    DispatchQueue.main.async {
                        self.name = name
                    }
                } else {
                    print("사용자 이름이 존재하지 않습니다.")
                    DispatchQueue.main.async {
                        self.name = "익명"
                    }
                }
            }
    }
}
