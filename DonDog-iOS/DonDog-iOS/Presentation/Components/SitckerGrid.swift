//
//  SitckerGrid.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/9/25.
//

import Kingfisher
import SwiftUI

struct StickerGrid: View {
    let columns: [GridItem]
    let rowSpacing: CGFloat
    
    let items: [StickerItem]
    let stickerImageURLs: [StickerItem.ID: URL]
    let loadingItemIDs: Set<StickerItem.ID>
    let selectedItemID: StickerItem.ID?

    @Binding var isCameraPresented: Bool
    var isStickerConfirmPresented: Binding<Bool>?
    let onItemAppear: (StickerItem.ID) -> Void
    let onItemTap: (StickerItem) -> Void
    let onPlusTap: (StickerItem) -> Void
    let onCameraDismiss: (StickerItem.ID) -> Void
    let onConfirmDismiss: ((StickerItem.ID) -> Void)?
    
    init(
        items: [StickerItem],
        remoteURLByItemID: [StickerItem.ID: URL],
        loadingItemIDs: Set<StickerItem.ID>,
        columns: [GridItem],
        rowSpacing: CGFloat = 16,
        isCameraPresented: Binding<Bool>,
        isStickerConfirmPresented: Binding<Bool>? = nil,
        onItemAppear: @escaping (StickerItem.ID) -> Void,
        onItemTap: @escaping (StickerItem) -> Void,
        onPlusTap: ((StickerItem) -> Void)? = nil,
        onCameraDismiss: @escaping (StickerItem.ID) -> Void,
        onConfirmDismiss: ((StickerItem.ID) -> Void)? = nil,
        selectedItemID: StickerItem.ID? = nil
    ) {
        self.items = items
        self.stickerImageURLs = remoteURLByItemID
        self.loadingItemIDs = loadingItemIDs
        self.columns = columns
        self.rowSpacing = rowSpacing
        self._isCameraPresented = isCameraPresented
        self.isStickerConfirmPresented = isStickerConfirmPresented
        self.onItemAppear = onItemAppear
        self.onItemTap = onItemTap
        self.onPlusTap = onPlusTap ?? onItemTap
        self.onCameraDismiss = onCameraDismiss
        self.onConfirmDismiss = onConfirmDismiss
        self.selectedItemID = selectedItemID
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: rowSpacing) {
            ForEach(items) { item in
                VStack {
                    StickerCellView(
                        title: item.title,
                        url: stickerImageURLs[item.id],
                        isLoading: loadingItemIDs.contains(item.id),
                        isSelected: item.id == selectedItemID,
                        onTapLoaded: { onItemTap(item) },
                        onTapEmpty: { onPlusTap(item) }
                    )
                }
                .contentShape(Rectangle())
                .task { onItemAppear(item.id) }
                .onChange(of: isCameraPresented) { _, presented in
                    if presented == false { onCameraDismiss(item.id) }
                }
                .background(
                    Group {
                        if let confirm = isStickerConfirmPresented, let onConfirmDismiss {
                            Color.clear.onChange(of: confirm.wrappedValue) { _, presented in
                                if presented == false { onConfirmDismiss(item.id) }
                            }
                        } else {
                            Color.clear
                        }
                    }
                )
            }
        }
    }
}

struct StickerCellView: View {
    let title: String
    let url: URL?
    let isLoading: Bool
    let isSelected: Bool
    let onTapLoaded: () -> Void
    let onTapEmpty: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let url {
                KFImage(url)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .opacity(isSelected ? 1.0 : 0.5)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTapLoaded)
            } else {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.ppGray600 : .secondary, style: StrokeStyle(lineWidth: 3, dash: [15, 5]))
                        .frame(width: 100, height: 100)

                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .ppGray600 : .primary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { if !isLoading { onTapEmpty() } }
            }

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
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
