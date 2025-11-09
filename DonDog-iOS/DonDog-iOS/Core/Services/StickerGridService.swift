//
//  StickerGridService.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

final class StickerGridService: ObservableObject {
    static let shared = StickerGridService()
    
    @Published var remoteURLByItemID: [StickerItem.ID: URL] = [:]
    @Published var loadingItemIDs: Set<StickerItem.ID> = []
    
    private init() {}

    func fetchStickerImage(for item: StickerItem, in category: StickerCategory) async {
        loadingItemIDs.insert(item.id)
        defer { loadingItemIDs.remove(item.id) }

        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let stickers: [StickerData] = try await DataManager.shared.fetchWhereEqual(
                path: "Stickers",
                field: "uid",
                isEqualTo: uid
            )

            let tags = [category.rawValue, item.title]
            let filtered = stickers.filter { $0.emotionTags == tags }
            let latest = filtered.max { lhs, rhs in
                let lhsDate = lhs.createdAt
                let rhsDate = rhs.createdAt
                return lhsDate < rhsDate
            }

            if let latest,
               let url = URL(string: latest.url) {
                remoteURLByItemID[item.id] = url
            }
        } catch {
            print("❌ 스티커 이미지 로드 실패: \(error)")
        }
    }
}

extension View {
    /// 카메라 촬영 플로우: 사진 찍기 버튼 탭 시 전면 카메라 화면을 fullScreenCover로 표시
    func cameraCaptureFlow(isPresented: Binding<Bool>, cameraVM: CameraViewModel) -> some View {
           self.modifier(CameraCoverModifier(isPresented: isPresented, cameraVM: cameraVM))
       }

    /// 기존 게시물 사진 선택 → 스티커 컨펌까지의 플로우를 하나의 modifier로 묶음
    func photoPickerStickerConfirmFlow(viewModel: SitckerCollectionViewModel) -> some View {
        self.modifier(PhotoPickerAndConfirmModifier(viewModel: viewModel))
    }
}

struct CameraCoverModifier: ViewModifier {
    @Binding var isPresented: Bool
    let cameraVM: CameraViewModel

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                CameraView(viewModel: cameraVM)
                    .ignoresSafeArea()
            }
    }
}

struct PhotoPickerAndConfirmModifier: ViewModifier {
    @ObservedObject var viewModel: SitckerCollectionViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                PhotoPickerView(viewModel: PhotoPickerViewModel()) { image in
                    viewModel.pickedImage = image
                    viewModel.showPhotoPicker = false
                    DispatchQueue.main.async {
                        viewModel.showStickerConfirm = true
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showStickerConfirm) {
                if let image = viewModel.pickedImage {
                    StickerConfirmView(
                        viewModel: StickerConfirmViewModel(
                            image: image,
                            onDone: { _ in
                                viewModel.showStickerConfirm = false
                            }
                        ),
                        route: .picker,
                        onRetake: {
                            viewModel.showStickerConfirm = false
                            DispatchQueue.main.async {
                                viewModel.showPhotoPicker = true
                            }
                        },
                        onClose: {
                            viewModel.showStickerConfirm = false
                        }
                    )
                }
            }
    }
}
