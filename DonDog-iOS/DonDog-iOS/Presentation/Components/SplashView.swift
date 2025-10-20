//
//  SplashView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/15/25.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showSplashView = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(0.35)
            
            VStack {
                Spacer()
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 94)
                    .padding(.bottom, 68)
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SplashView()
}
