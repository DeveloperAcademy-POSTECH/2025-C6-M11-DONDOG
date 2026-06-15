//
//  OnBoardingView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 11/19/25.
//

import SwiftUI

struct InitialOnBoardingView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var currentStep: InitialOnBoardingStep = .first
    @AppStorage("hasSeenInitialOnboarding") var hasSeenInitialOnboarding: Bool = false
    
    private var firstContent: InitialOnBoardingContent {
        InitialOnBoardingContent(
            imageName: "OnBoardingStep1",
            title: "사진 두 장이면 충분해요",
            description: "사랑하는 가족과의 대화, 부담으로 느껴질 때가 있죠.\n사진만으로 가볍게 안부를 전해요.",
            buttonTitle: "다음으로"
        )
    }
    
    private var secondContent: InitialOnBoardingContent {
        InitialOnBoardingContent(
            imageName: "OnBoardingStep2",
            title: "나만의 스티커로 글보다 빠르게",
            description: "어떻게 답장할지 고민하지 마세요.\n재미있게 붙이면, 마음은 저절로 전해져요.",
            buttonTitle: "시작하기"
        )
    }
    
    var body: some View {
        ZStack {
            if currentStep == .first {
                InitialOnBoardingContentView(
                    content: firstContent,
                    onNext: goToNextStep
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            } else {
                InitialOnBoardingContentView(
                    content: secondContent,
                    onNext: goToNextStep
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            currentStep = .first
        }
    }
    
    private func goToNextStep() {
        switch currentStep {
        case .first:
            currentStep = .second
        case .second:
            hasSeenInitialOnboarding = true
            
        }
    }
}

struct InitialOnBoardingContent {
    let imageName: String
    let title: String
    let description: String
    let buttonTitle: String
}

enum InitialOnBoardingStep: Int, CaseIterable {
    case first
    case second
}

struct InitialOnBoardingContentView: View {
    let content: InitialOnBoardingContent
    let onNext: () -> Void
    let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.ppWhite
                .ignoresSafeArea()
            
            VStack {
                Image(content.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width)
                
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
        // .ignoresSafeArea(.container, edges: .vertical)
    }
}

#Preview {
    InitialOnBoardingContentView(
        content: InitialOnBoardingContent(
            imageName: "OnBoardingStep1",
            title: "사진 두 장이면 충분해요",
            description: "사랑하는 가족과의 대화, 부담으로 느껴질 때가 있죠.\n사진만으로 가볍게 안부를 전해요.",
            buttonTitle: "다음으로"
        ),
        onNext: {}
    )
}

#Preview {
    InitialOnBoardingView()
}
