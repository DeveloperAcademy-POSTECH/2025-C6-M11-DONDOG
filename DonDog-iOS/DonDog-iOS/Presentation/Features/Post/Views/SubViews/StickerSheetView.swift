//
//  StickerSheetView.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/16/25.
//

import Kingfisher
import SwiftUI

struct StickerSheetView: View {
    @StateObject private var viewModel = StickerSheetViewModel()
    @State private var select = 0
    @Environment(\.dismiss) var dismiss
    
    private let category = StickerCategory.allCases
    
    var body: some View {
        NavigationStack {
            VStack {
                StickerSheetCollectionView(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $select) {
                        ForEach(0..<category.count, id: \.self) { index in
                            Text(category[index].rawValue).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                    .onChange(of: select) { newValue in
                        viewModel.selectedCategory = category[newValue]
                    }
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
    @ObservedObject var viewModel: StickerSheetViewModel
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.returnStickerItems(for: viewModel.selectedCategory)) { item in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.06))
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                                )
                            
                            if let url = viewModel.remoteURLByItemID[item.id] {
                                KFImage(url)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(12)
                            } else {
                                if viewModel.loadingItemIDs.contains(item.id) {
                                    ProgressView()
                                } else {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 28, weight: .semibold))
                                }
                            }
                        }
                    }
                    .task(id: item.id) {
                        await viewModel.fetchStickerImage(forID: item.id)
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }
}
