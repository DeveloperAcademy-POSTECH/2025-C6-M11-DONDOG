//
//  CustomSegmentedControl.swift
//  DonDog-iOS
//
//  Created by 조유진 on 11/4/25.
//

import SwiftUI

struct CustomSegmentedControl: View {
    enum PostAuthorType { case partnerArchive, myArchive }
    
    let selected: PostAuthorType
    let onChange: (PostAuthorType) -> Void
    
    @Namespace private var nameSpace
    @State private var pressBounce = false
    
    var body: some View {
        HStack(spacing: 0) {
            segment("가족", .partnerArchive)
            segment("나", .myArchive)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.ddGray300)
        .clipShape(Capsule())
        .fixedSize()
        .animation(.bouncy(duration: 0.55, extraBounce: 0.45), value: selected)
        .animation(.bouncy(duration: 0.35, extraBounce: 0.35), value: pressBounce)
    }
    
    @ViewBuilder
    private func segment(_ title: String, _ type: PostAuthorType) -> some View {
        Button {
            pressBounce = true
            onChange(type)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                pressBounce = false
            }
        } label: {
            Text(title)
                .font(.subtitleSemiBold16)
                .foregroundStyle(.ddGray1000)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    ZStack {
                        if selected == type {
                            Capsule()
                                .fill(.ddWhite)
                                .matchedGeometryEffect(id: "pill", in: nameSpace)
                                .shadow(color: .ddBlack.opacity(0.08), radius: 1, x: 0, y: 1)
                        }
                    },
                    alignment: .center
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle()) // 탭 영역 넓게
        .hapticFeedback(.medium)
    }
}
