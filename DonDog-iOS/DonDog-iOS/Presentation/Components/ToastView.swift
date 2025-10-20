//
//  ToastView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/20/25.
//

import SwiftUI

struct ToastView: View {
    @State var toastText: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .font(.caption)
        
            Text("\(toastText)")
                .font(.captionRegular14)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.ddGray100)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(.ddGray600)
        .cornerRadius(20)
    }
}

#Preview {
    ToastView(toastText: "본인이 작성한 글만 삭제할 수 있어요")
}
