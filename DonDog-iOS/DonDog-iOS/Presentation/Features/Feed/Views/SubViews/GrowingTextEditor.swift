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
        guard range > 0 else { return 74 }
        let progress = (dynamicHeight - minHeight) / range
        return 74 - (62 * progress)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextEditor(text: $text)
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .scrollContentBackground(.hidden)
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
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        dynamicHeight = min(max(textSize + 24, minHeight), maxHeight)
                                    }
                                }
                            }
                    }
                )
                .frame(height: dynamicHeight > 0 ? dynamicHeight : minHeight)
                .focused($isFocused)
                .background(Color.ddGray100)
                .cornerRadius(currentRadius)
                .animation(.easeOut(duration: 0.15), value: currentRadius)
            
            if text.isEmpty && !isFocused {
                Text("댓글을 입력해 주세요...")
                    .font(.bodyRegular16)
                    .foregroundColor(.ddGray600)
                    .padding(.leading, 16)
            }
        }
    }
}
