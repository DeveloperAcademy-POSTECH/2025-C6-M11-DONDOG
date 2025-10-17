//
//  WelcomeView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/15/25.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(0.35)
            
            VStack {
                Spacer()
                Text("Winky")
                Spacer()
            }
            VStack {
                Spacer()
                CustomButton(title: "전화번호로 시작하기", isEnable: true, action: {
                    coordinator.authShowWithdraw = false
                    coordinator.push(.auth)
                }
                )
            }
            .padding(.horizontal, 20)
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    WelcomeView()
}
