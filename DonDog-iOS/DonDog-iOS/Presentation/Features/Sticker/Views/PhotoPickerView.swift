//
//  PhotoPickerView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUI

struct PhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: PhotoPickerViewModel
    
    let selectPhoto: (UIImage) -> Void
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(viewModel.items, id: \.postId) { post in
                                if let imageURL = URL(string: post.frontImageURL) {
                                    ZStack(alignment: .topTrailing) {
                                        KFImage(imageURL)
                                            .placeholder { Color(.secondarySystemBackground) }
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: screenWidth/3 + 3, height: 160)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .onTapGesture { viewModel.selectedURL = imageURL }
                                        
                                        if viewModel.selectedURL == imageURL {
                                            Color(.systemGray5).opacity(0.35)
                                                .frame(width: screenWidth/3 + 3, height: 160)
                                                .allowsHitTesting(false)
                                                .overlay(
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 22, weight: .semibold))
                                                        .foregroundStyle(Color.accentColor)
                                                        .padding(8),
                                                    alignment: .topTrailing
                                                )
                                        }
                                    }
                                } else {
                                    Color(.secondarySystemBackground)
                                        .frame(width: 120, height: 160)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("사진 선택")
                        .font(.headline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        guard viewModel.selectedURL != nil else { return }
                        Task {
                            do {
                                let sticker = try await viewModel.makeStickerFromSelected()
                                selectPhoto(sticker)
                                dismiss()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(viewModel.selectedURL == nil)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadInitial() }
        }
    }
}
