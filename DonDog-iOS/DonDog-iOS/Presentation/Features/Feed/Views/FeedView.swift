//
//  FeedView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI
import FirebaseAuth

struct FeedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: FeedViewModel
    
    var body: some View {
        VStack {
            Text("Feed View")
            
            Button("로그아웃") {
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("로그아웃 실패: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    FeedView(viewModel: FeedViewModel())
}
