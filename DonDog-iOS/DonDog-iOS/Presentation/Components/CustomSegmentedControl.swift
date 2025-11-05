//
//  CustomSegmentedControl.swift
//  DonDog-iOS
//
//  Created by 조유진 on 11/4/25.
//

import SwiftUI

struct CustomSegmentedControl<Item: Hashable & Identifiable>: View {
    let items: [Item]
    @Binding var selectedItem: Item
    let titleProvider: (Item) -> String
    
    @Namespace private var nameSpace
    @State private var pressBounce = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                segment(item)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.ddGray300)
        .clipShape(Capsule())
        .fixedSize()
        .animation(.bouncy(duration: 0.55, extraBounce: 0.45), value: selectedItem)
        .animation(.bouncy(duration: 0.35, extraBounce: 0.35), value: pressBounce)
    }
    
    @ViewBuilder
    private func segment(_ item: Item) -> some View {
        Button {
            pressBounce = true
            selectedItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                pressBounce = false
            }
        } label: {
            Text(titleProvider(item))
                .font(.subtitleSemiBold16)
                .foregroundStyle(.ddGray1000)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    ZStack {
                        if selectedItem == item {
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
