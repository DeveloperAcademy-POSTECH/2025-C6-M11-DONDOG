//
//  CommentRowViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import Combine
import FirebaseFirestore
import FirebaseAuth

final class CommentRowViewModel: ObservableObject {
    @Published var name: String = "익명"
    @Published var createdAt: Date = Date()
    @Published var text: String = ""
    
    func setCommentData(comment: CommentData) {
        fetchUserName(of: comment.authorId)
        createdAt = comment.createdAt.dateValue()
        text = comment.text
    }
    
    private func fetchUserName(of authorId: String) {
        Firestore.firestore()
            .collection("Users")
            .document(authorId)
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
