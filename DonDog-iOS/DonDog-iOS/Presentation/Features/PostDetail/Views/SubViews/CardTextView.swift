//
//  CardTextView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CardTextView: View {
    @StateObject var viewModel = CardTextViewModel()
    
    let caption: String
    let authorId: String
    let createdAt: Date
    
    var body: some View {
        VStack {
            VStack {
                if !caption.isEmpty {
                    Text(caption)
                        .font(.polaroidCaptionRegular20)
                        .foregroundStyle(.ddGray1000)
                } else {
                    Text("")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 27)
            
            HStack(spacing: 4) {
                Text(viewModel.name)
                    .foregroundStyle(.ddGray600)
                
                Text(DateUtils.relativeTimeString(from: createdAt))
                    .foregroundStyle(.ddGray500)
            }
            .font(.captionRegular13)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
    }
}
