//
//  InviteView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import SwiftUI

struct InviteView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: InviteViewModel
    
    var body: some View {
        VStack {
            Text("Invite View")
                .font(.title)
        
            Text(viewModel.inviteText)
                .font(.title2)
                .padding()
            
            Text(viewModel.remainTimeText)
                .foregroundColor(.secondary)
            
            Button("feed로 이동") {
                coordinator.replaceRoot(.feed)
            }
            
        }
        .task { viewModel.fetchInviteCodeandExpireDate() }
    }
}

#Preview {
    InviteView(viewModel: InviteViewModel())
}
