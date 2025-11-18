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
                Color.ppWhite
                
                VStack(spacing: 10) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.ppSubPrime15)
                    Text("네트워크가 불안정해요.")
                        .font(.bodyMedium16)
                        .foregroundStyle(Color.ppGray600)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 4) {
                            Text("연결 재시도")
                                .font(.captionRegular13)
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(Color.ppWhite)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.ppPrime)
                        .cornerRadius(999)
                    }
                    
                }
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    NetworkErrorView(isUnstable: true)
}
