//
//  ProfileSetupView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/4/25.
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ProfileSetupViewModel
    
    var body: some View {
        Text("profile setup view")
        
        Button("피드 이동하기") {
            coordinator.replaceRoot(.feed)
        }

    }
}
