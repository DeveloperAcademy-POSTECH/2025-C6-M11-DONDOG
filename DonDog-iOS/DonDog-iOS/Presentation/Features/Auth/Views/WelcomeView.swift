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
            Color.ppPrime
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 12.6) {
                    Image("SplashLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 245)
                    Text("서로의 하루를 공유하는 가장 즐거운 방법")
                        .foregroundStyle(Color.ppWhite)
                        .font(.captionMedium14)
                }
                
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
