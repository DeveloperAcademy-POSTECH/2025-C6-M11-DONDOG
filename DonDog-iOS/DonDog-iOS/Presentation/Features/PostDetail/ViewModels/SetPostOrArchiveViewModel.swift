//
//  SetPostOrArchiveViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/26/25.
//

import Combine

final class SetPostOrArchiveViewModel: ObservableObject {
    // TODO: 공통의 Post 구조체 가지도록 설계
    // TODO: ArchivePost들 가져오도록 init
    @Published var posts: [ArchivePost] = []
    
}
