//
//  OnBoardingContentView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 11/19/25.
//

import SwiftUI

struct OnBoardingContent {
    let imageName: String
    let title: String
    let description: String
    let buttonTitle: String
}

enum OnBoardingStep: Int, CaseIterable {
    case first
    case second
}

struct OnBoardingContentView: View {
    let content: OnBoardingContent
    let onNext: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.ppWhite
                .ignoresSafeArea()
            
            VStack {
                GeometryReader { geometry in
                    VStack {
                        Image(content.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width)
                    }
                }
                
                VStack(spacing: 68) {
                    VStack(spacing: 10) {
                        Text(content.title)
                            .font(.titleBold24)
                            .foregroundStyle(.ppGray700)
                        
                        Text(content.description)
                            .font(.bodyRegular16)
                            .foregroundStyle(.ppGray600)
                    }
                    .multilineTextAlignment(.center)
                    
                    CustomButton(title: content.buttonTitle, action: onNext)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 22)
            }
        }
    }
}

#Preview {
    OnBoardingContentView(
        content: OnBoardingContent(
            imageName: "OnBoardingStep1",
            title: "사진 두 장이면 충분해요",
            description: "사랑하는 가족과의 대화, 부담으로 느껴질 때가 있죠.\n사진만으로 가볍게 안부를 전해요.",
            buttonTitle: "다음으로"
        ),
        onNext: {}
    )
}
