//
//  PostDetailViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import Combine
import FirebaseAuth

final class PostDetailViewModel: ObservableObject {
    
    @Published var showDeleteConfirmAlert = false
    @Published var showUnauthorizedAlert = false
    
    func handleDeleteRequest() {
        // TODO: 해당 게시물의 post 정보 가져오기
        let postAuthorId: String = ""
        // TODO: currentUser 정보 User Singleton에서 가져오기
        let currentUserId = Auth.auth().currentUser!.uid
        
        if postAuthorId == currentUserId {
            showDeleteConfirmAlert = true
        } else {
            showUnauthorizedAlert = true
        }
    }
    
    func deletePost() async {
        // TODO: 해당 게시물 삭제 로직 구현
        updateDB()
    }
    
    private func updateDB() {
        // TODO: 새로고침(데이터 업데이트 적용)
    }
}
