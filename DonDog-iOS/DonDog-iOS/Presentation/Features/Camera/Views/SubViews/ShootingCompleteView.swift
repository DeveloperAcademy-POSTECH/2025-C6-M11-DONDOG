//
//  ShootingCompleteView.swift
//  DonDog-iOS
//
//  Created by Ito on 11/11/25.
//

import SwiftUI

struct ShootingCompleteView: View {
    
    @Binding var isVisible: Bool
    var onDismiss: () -> Void
    
    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("촬영완료")
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 36)
                }
                .padding()
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if isVisible {
                        withAnimation {
                            isVisible = false
                            onDismiss()
                        }
                    }
                }
            }
        }
    }
}
