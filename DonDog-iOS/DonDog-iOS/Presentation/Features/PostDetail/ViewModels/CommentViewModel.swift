//
//  CommentViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import Combine

final class CommentViewModel: ObservableObject {
    @Published var text: String
    
    init() {
        text = ""
    }
    
    func saveComment() async {
        // TODO: 댓글 저장 로직 구현
    }
}
