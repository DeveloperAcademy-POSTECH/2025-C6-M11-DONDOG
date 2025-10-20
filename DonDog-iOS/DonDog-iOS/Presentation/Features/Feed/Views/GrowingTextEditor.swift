//
//  GrowingTextEditor.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/19/25.
//

import SwiftUI

struct GrowingTextEditor: View {
    @Binding var text: String
    let minHeight: CGFloat
    let maxHeight: CGFloat
    @FocusState var isFocused: Bool
    
    @State private var dynamicHeight: CGFloat = 0
    
    var currentRadius: CGFloat {
        let range = maxHeight - minHeight
        if range == 0 { return minHeight }
        let progress = (dynamicHeight - minHeight) / range
        return 32 - (16 * progress)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextEditor(text: $text)
                .padding(.leading, 20)
                .padding(.top, 8)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onChange(of: text) { _, _ in
                                let textSize = text.boundingRect(
                                    with: CGSize(width: geometry.size.width - 36, height: .infinity),
                                    options: .usesLineFragmentOrigin,
                                    attributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
                                    context: nil
                                ).height
                                
                                DispatchQueue.main.async {
                                    dynamicHeight = min(max(textSize + 24, minHeight), maxHeight)
                                }
                            }
                    }
                )
            
                .frame(height: dynamicHeight > 0 ? dynamicHeight : minHeight)
                .focused($isFocused)
            
            if text.isEmpty && !isFocused {
                Text("댓글을 입력해 주세요...")
                    .foregroundColor(.gray)
                    .padding(.leading, 24)
                    .padding(.vertical, 8)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: currentRadius)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .padding(.bottom, 12)
        .animation(.easeOut(duration: 0.15), value: dynamicHeight)
    }
}
