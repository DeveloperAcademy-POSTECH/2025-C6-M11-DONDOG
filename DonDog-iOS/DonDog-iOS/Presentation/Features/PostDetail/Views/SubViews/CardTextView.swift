//
//  CardTextView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CardTextView: View {
    let caption: String
    let authorId: String
    let createdAt: Date
    
    // TODO: User 싱글톤 사용
    @State private var name: String = "익명"
    
    var body: some View {
        VStack {
            VStack {
                if !caption.isEmpty {
                    Text(caption)
                        .font(.polaroidCaptionRegular20)
                        .foregroundStyle(.ddGray1000)
                } else {
                    Text("")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 27)
            
            HStack(spacing: 4) {
                Text(name)
                    .foregroundStyle(.ddGray600)
                
                Text(DateUtils.relativeTimeString(from: createdAt))
                    .foregroundStyle(.ddGray500)
            }
            .font(.captionRegular13)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .onAppear {
            fetchUserName()
            
        }
    }
    
    // TODO: User 싱글톤에서 이름 가져오기
    private func fetchUserName() {
        Firestore.firestore()
            .collection("Users")
            .document(authorId)
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
