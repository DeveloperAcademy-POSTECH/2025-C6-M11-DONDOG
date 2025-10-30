//
//  NetworkStatusOverlay.swift
//  DonDog-iOS
//
//  Created by 이주현 on 10/20/25.
//

import SwiftUI

struct NetworkErrorView: View {
    let isUnstable: Bool
    
    var body: some View {
        if isUnstable {
            ZStack {
                Color.white
                
                LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .opacity(0.35)
                
                VStack(spacing: 10) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 32))
                    Text("네트워크가 불안정해요.")
                        .font(.bodyMedium16)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString),
                            UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 4) {
                            Text("연결 재시도")
                                .font(.captionRegular13)
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(Color.ddGray100)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.ddPrimaryBlue)
                        .cornerRadius(999)
                    }

                }
                .foregroundStyle(Color.ddPrimaryBlue)
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    NetworkErrorView(isUnstable: true)
}
