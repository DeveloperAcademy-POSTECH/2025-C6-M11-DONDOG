//
//  NotConnectedView.swift
//  DonDog-iOS
//
//  Created by Ito on 11/19/25.
//

import SwiftUI

struct NotConnectedView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        coordinator.push(.setting)
                    } label: {
                        Image(systemName: "gear")
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.ppPrime)
                            .padding(.vertical, 8)
                            .padding(.trailing, 20)
                    }
                }
                Spacer()
            }
            
            VStack(spacing: 0) {
                Spacer()
                Image(systemName: "person.fill.xmark")
                    .foregroundStyle(Color.ppPrime50)
                    .font(.system(size: 40))
                Text("아직 가족과 연결되지 않았어요\n아래 버튼으로 가족을 초대할 수 있어요")
                    .font(.bodyRegular16)
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ppGray500)
                    .padding(10)
                Button {
                    coordinator.inviteShowSentHint = false
                    coordinator.push(.invite)
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Text("가족 초대하기")
                            .foregroundStyle(Color.ppGray200)
                            .font(.captionRegular14)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.ppPrime)
                    .cornerRadius(999)
                }
                Spacer()
            }
        }
        .background(.ppWhite)
    }
}
