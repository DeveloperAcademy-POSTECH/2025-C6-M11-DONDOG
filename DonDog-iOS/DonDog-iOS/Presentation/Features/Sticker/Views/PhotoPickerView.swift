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
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: PhotoPickerViewModel
    
    @State private var stickerImage: UIImage?
    
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
            CustomNavigationBar(
                leadingType: .back(action: { coordinator.pop() }),
                centerType: .title(title: "사진 선택"),
                trailingType: .textButton(
                    title: "완료",
                    isEnabled: viewModel.selectedURL != nil,
                    action: {
                        guard viewModel.selectedURL != nil else { return }
                        Task {
                            do {
                                let sticker = try await viewModel.makeStickerFromSelected()
                                
                                await MainActor.run {
                                    self.stickerImage = sticker
                                }
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                        }
                    }
                ),
                navigationColor: .black
            )
            .padding(.horizontal, 16)
            
            if viewModel.items.isEmpty {
                VStack {
                    Spacer()
                    
                    Image(UserPairingStore.shared.myRole == "parent" ? "ParentEmptyView" : "ChildEmptyView")
                        .padding(.bottom, 16)
                   
                    Text("게시물이 없어\n사진을 선택할 수 없어요")
                        .font(.bodyRegular18)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.ppGray600)
                        .lineSpacing(4)
                    Spacer()
                }
            } else {
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(viewModel.items, id: \.postId) { post in
                                    if let imageURL = URL(string: post.frontImageURL) {
                                        ZStack(alignment: .topTrailing) {
                                            KFImage(imageURL)
                                                .placeholder {
                                                    Color(.secondarySystemBackground)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: .infinity, maxHeight: 150)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .contentShape(Rectangle())
                                                .onTapGesture { viewModel.selectedURL = imageURL }
                                            
                                            if viewModel.selectedURL == imageURL {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(.ddBlack).opacity(0.4))
                                                    .frame(maxWidth: .infinity, maxHeight: 150)
                                                    .overlay(
                                                        Image(systemName: "checkmark.circle")
                                                            .font(.system(size: 24))
                                                            .foregroundStyle(Color.ppPrime)
                                                            .padding(8),
                                                        alignment: .center
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
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
        .task { await viewModel.loadInitial() }
        .backHiddenSwipeEnabled()
        .fullScreenCover(
            isPresented: Binding(
                get: { stickerImage != nil },
                set: { newValue in
                    if !newValue {
                        stickerImage = nil
                    }
                }
            )
        ) {
            if stickerImage != nil {
                StickerConfirmView(
                    viewModel: StickerConfirmViewModel(image: stickerImage),
                    route: .picker,
                    onRetake: {
                        viewModel.selectedURL = nil
                        stickerImage = nil
                    },
                    onComplete: {
                        viewModel.selectedURL = nil
                        stickerImage = nil
                        coordinator.pop()
                    },
                    onUploaded: { tags in
                        Task {
                            await StickerGridService.shared.reloadSticker(tags: tags)
                        }
                    }
                )
            }
        }
    }
}
