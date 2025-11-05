//
//  TextViewModel.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/29/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class TextViewModel: ObservableObject {
    let connectUserInfo = UserPairingStore.shared
    @Published var name: String?
    
    func fetchUserName(of authorId: String) {
        if authorId == connectUserInfo.myUid {
            name = connectUserInfo.myName
        } else {
            name = connectUserInfo.partnerName
        }
    }
}
