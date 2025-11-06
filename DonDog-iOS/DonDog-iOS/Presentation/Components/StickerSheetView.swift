//
//  StickerSheetView.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/16/25.
//

import SwiftUI

struct StickerSheetView: View {
    @State private var select = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                StickerSheetCollectionView()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $select) {
                        Text("애정").tag(0)
                        Text("걱정").tag(1)
                        Text("일상").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline)
                    }
                }
            }
        }
    }
}

private struct StickerSheetCollectionView: View {
    private let items = Array(1...6)
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(items, id: \.self) { item in
                    Text("Item \(item)")
                        .font(.headline)
                }
            }
            .padding(.bottom, 4)
        }
    }
}
