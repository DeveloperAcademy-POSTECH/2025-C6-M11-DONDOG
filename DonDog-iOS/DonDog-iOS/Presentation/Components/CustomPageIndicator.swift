//
//  CustomPageIndicator.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/17/25.
//

import SwiftUI

struct CustomPageIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    let backgroundColor: Color
    let textColor: Color
    
    var body: some View {
        Text("\(currentIndex)/\(totalCount)")
            .font(.captionRegular13)
            .foregroundColor(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
    }
}

#Preview {
    // 메인
    CustomPageIndicator(
        currentIndex: 1, totalCount: 4, backgroundColor: .ddWhite50, textColor: .ddGray600
    )
    
    // 아카이브 디테일
    CustomPageIndicator(
        currentIndex: 1, totalCount: 4, backgroundColor: .ddBlack20, textColor: .ddWhite
    )
    
}
