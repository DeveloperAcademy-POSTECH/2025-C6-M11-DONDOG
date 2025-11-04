//
//  PhotoPickerView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/4/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Kingfisher

struct PhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (UIImage, URL) -> Void
    
    init(onPick: @escaping (UIImage, URL) -> Void = { _, _ in }) {
        self.onPick = onPick
    }
    
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
    
    @State var items: [PostData] = []
    @State var isLoading = false
    @State var errorMessage: String?
    
    @State private var selectedURL: URL?
    @State private var selectedImage: UIImage?

    private let dataManager: DataManagerProtocol = DataManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(items, id: \.postId) { post in
                                if let thumbURL = URL(string: post.frontImageURL) {
                                    ZStack(alignment: .topTrailing) {
                                        KFImage(thumbURL)
                                            .placeholder { Color(.secondarySystemBackground) }
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 160)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                Task {
                                                    self.selectedURL = thumbURL
                                                    self.selectedImage = nil
                                                    do {
                                                        let img = try await dataManager.downloadImage(from: post.frontImageURL)
                                                        self.selectedImage = img
                                                    } catch {
                                                        self.errorMessage = error.localizedDescription
                                                        self.selectedURL = nil
                                                        self.selectedImage = nil
                                                    }
                                                }
                                            }

                                        if selectedURL == thumbURL {
                                            Color(.systemGray5).opacity(0.35)
                                                .frame(width: 120, height: 160)
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
                        if let img = selectedImage, let url = selectedURL {
                            onPick(img, url)
                            dismiss()
                        }
                    }
                    .disabled(selectedImage == nil)
                }
            }
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
