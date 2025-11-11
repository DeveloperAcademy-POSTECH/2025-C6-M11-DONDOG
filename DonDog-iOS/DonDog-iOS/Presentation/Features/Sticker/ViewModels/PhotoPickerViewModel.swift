//
//  PhotoPickerViewModel.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/7/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import Kingfisher
import UIKit

final class PhotoPickerViewModel: ObservableObject {
    @Published var items: [PostData] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedURL: URL?

    private let dataManager: DataManagerProtocol

    init(dataManager: DataManagerProtocol = DataManager.shared) {
        self.dataManager = dataManager
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

    func makeStickerFromSelected() async throws -> UIImage {
        guard let url = selectedURL else { throw NSError(domain: "PhotoPicker", code: 0, userInfo: [NSLocalizedDescriptionKey: "이미지가 선택되지 않았습니다."]) }
        let retrieve = try await KingfisherManager.shared.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh])
        let uiImage = retrieve.image
        guard let sticker = await StickerService().makeSticker(from: uiImage) else {
            throw NSError(domain: "PhotoPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: "스티커 생성에 실패했습니다."])
        }
        return sticker
    }
}
