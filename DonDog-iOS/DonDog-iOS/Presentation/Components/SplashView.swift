//
//  SplashView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/15/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack {
            Spacer()
            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 245)
            Text("서로의 하루를 공유하는 가장 즐거운 방법")
                .foregroundStyle(Color.ppBlack)
                .font(.captionMedium14)
            Spacer()
            Rectangle()
                .fill(Color.clear)
                .frame(height: 68)
        }
        .background(.ppWhite)
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SplashView()
}
