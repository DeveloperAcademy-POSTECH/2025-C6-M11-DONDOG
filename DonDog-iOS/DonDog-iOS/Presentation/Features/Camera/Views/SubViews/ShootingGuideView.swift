//
//  ShootingGuideView.swift
//  DonDog-iOS
//
//  Created by Ito on 11/11/25.
//

import SwiftUI

enum StepIntroType {
    case front
    case back
    
    var title: String {
        switch self {
        case .front: return "Step 1."
        case .back:  return "Step 2."
        }
    }
    
    var message: String {
        switch self {
        case .front: return "셀카를 찍어주세요!"
        case .back:  return "후면 카메라로 풍경을 찍어주세요!"
        }
    }
}

struct ShootingGuideView: View {
    var step: StepIntroType
    
    var body: some View {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text(step.title).font(.title2).foregroundColor(.red)
                            Text(step.message).foregroundColor(.white)
                        }
                        Image(systemName: "camera")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                    }
                    .padding(.bottom, 36)
                }
                .padding()
            }
    }
}
