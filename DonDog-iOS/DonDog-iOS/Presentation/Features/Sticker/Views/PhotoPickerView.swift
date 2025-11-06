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
    let selectPhoto: (UIImage) -> Void
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
    
    @State var items: [PostData] = []
    @State var isLoading = false
    @State var errorMessage: String?
    
    @State private var selectedURL: URL?
    @State private var selectedImage: UIImage?

    private let dataManager: DataManagerProtocol = DataManager.shared
    private let screenWidth = UIScreen.main.bounds.width

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(items, id: \.postId) { post in
                                if let imageURL = URL(string: post.frontImageURL) {
                                    ZStack(alignment: .topTrailing) {
                                        KFImage(imageURL)
                                            .placeholder { Color(.secondarySystemBackground) }
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: screenWidth/3 + 3, height: 160)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .onTapGesture { selectedURL = imageURL }

                                        if selectedURL == imageURL {
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
                        guard let url = selectedURL else { return }
                        Task {
                            let retrieve = try await KingfisherManager.shared.retrieveImage(
                                with: url,
                                options: [.fromMemoryCacheOrRefresh]
                            )
                            let uiImage = retrieve.image
                            
                            guard let sticker = await StickerService().makeSticker(from: uiImage) else {
                                return
                            }
                            selectPhoto(sticker)
                            dismiss()
                        }
                    }
                    .disabled(selectedURL == nil)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadInitial() }
        }
        
    }
    
    func loadInitial() async {
        errorMessage = nil
        items.removeAll()
        await loadMore()
    }

    func loadMore() async {
        guard !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do {
            // TODO: uid, roomId 싱글톤에서 가져오는걸로 수정
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let roomId = try await dataManager.getCurrentUserRoomId()

            let all: [PostData] = try await dataManager.fetchCollection(
                path: "Rooms/\(roomId)/posts",
                orderBy: "createdAt",
                descending: true
            )
            self.items = all.filter { $0.authorId == uid && !$0.frontImageURL.isEmpty }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
