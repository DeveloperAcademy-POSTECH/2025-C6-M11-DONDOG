//
//  ProfileEditView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/9/25.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: EditProfileViewModel
    
    var body: some View {
        Text("Profile Edit View")
    }
}

#Preview {
    EditProfileView(viewModel: EditProfileViewModel())
}
