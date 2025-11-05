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
    
    var body: some View {
        Text("\(currentIndex)/\(totalCount)")
            .font(.captionRegular13)
            .foregroundColor(.ddGray600)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ddGray100)
            )
    }
}
