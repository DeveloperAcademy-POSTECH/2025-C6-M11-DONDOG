//
//  SitckerCollectionView.swift
//  DonDog-iOS
//
//  Created by 이주현 on 11/1/25.
//

import PhotosUI
import SwiftUI
import Combine

// MARK: - Domain Models
enum StickerCategory: String, CaseIterable, Identifiable {
    case affection = "애정"
    case worry = "걱정"
    case praise = "칭찬"
    case humor = "유머"
    case daily = "일상"
    var id: String { rawValue }
}

struct StickerItem: Identifiable, Hashable {
    let id = UUID()
    let title: String // 세부 감정 문구 (예: "보고싶다")
    var image: UIImage? // 누끼 완료된 스티커 이미지 (없으면 + 버튼)
}

struct StickerCategoryData {
    static let itemsByCategory: [StickerCategory: [StickerItem]] = {
        var dict: [StickerCategory: [StickerItem]] = [:]
        
        dict[.affection] = [
            .init(title: "보고싶다", image: nil),
            .init(title: "사랑해", image: nil),
            .init(title: "안아줄게", image: nil),
            .init(title: "그리워", image: nil),
            .init(title: "빨리 만나자", image: nil),
            .init(title: "네 편이야", image: nil),
            .init(title: "고마워", image: nil)
        ]

        dict[.worry] = [
            .init(title: "괜찮아?", image: nil),
            .init(title: "밥 먹었어?", image: nil),
            .init(title: "무리하지 마", image: nil),
            .init(title: "아프지 마", image: nil),
            .init(title: "조심히 들어가", image: nil),
            .init(title: "연락 기다릴게", image: nil),
            .init(title: "천천히 해", image: nil),
            .init(title: "늦게까지 깨어있지 마", image: nil)
        ]

        dict[.praise] = [
            .init(title: "잘했어", image: nil),
            .init(title: "최고야", image: nil),
            .init(title: "대단해", image: nil),
            .init(title: "멋지다", image: nil),
            .init(title: "자랑스러워", image: nil),
            .init(title: "고생했어", image: nil),
            .init(title: "너답다", image: nil)
        ]

        dict[.humor] = [
            .init(title: "빵 터짐", image: nil),
            .init(title: "아재개그각", image: nil),
            .init(title: "오늘의 밈", image: nil),
            .init(title: "갸꿀잼", image: nil),
            .init(title: "드립 인정", image: nil),
            .init(title: "ㅋㅋㅋㅋ", image: nil),
            .init(title: "크크큭", image: nil)
        ]

        dict[.daily] = [
            .init(title: "오늘도 화이팅", image: nil),
            .init(title: "커피 한 잔", image: nil),
            .init(title: "퇴근!", image: nil),
            .init(title: "운동 가자", image: nil),
            .init(title: "산책 갈래", image: nil),
            .init(title: "날씨 좋네", image: nil),
            .init(title: "휴식 모드", image: nil)
        ]
        
        return dict
    }()
}

// MARK: - View
struct SitckerCollectionView: View {
    @State private var selectedCategory: StickerCategory = .affection
    @State private var itemsByCategory: [StickerCategory: [StickerItem]] = StickerCategoryData.itemsByCategory
    @StateObject private var cameraVM = CameraViewModel()

    // 하단 액션바 표시 상태 및 타겟 아이템
    @State private var showActionBar: Bool = false
    @State private var targetItemID: StickerItem.ID?

    // 사진 선택 (기존 게시물/앨범)
    @State private var showPhotoPicker: Bool = false
    @State private var pickedPhotoItem: PhotosPickerItem?

    // 카메라 촬영
    @State private var showCamera: Bool = false
    @State private var capturedImage: UIImage?

    // Grid 3x2
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let actionBarAnimDuration: Double = 0.25

    var body: some View {
        let base = mainContent
            .background(dismissBackdrop)
            .overlay(alignment: .bottom) { actionBar }
            .animation(.easeInOut, value: showActionBar)

        return base
            .padding(.horizontal, 12)
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $pickedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: pickedPhotoItem) { _, newValue in
                Task { await handlePickedPhoto(newValue) }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(viewModel: cameraVM)
                    .ignoresSafeArea()
            }
            .onChange(of: cameraVM.frontImage) { img in
                guard let img else { return }
                applySelectedImage(img)
                showCamera = false
            }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // 상단 카테고리 탭
            categoryTabs
                .padding(.vertical, 12)

            // 세부 감정 그리드 (3x2)
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(items(for: selectedCategory)) { item in
                        stickerCell(item)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                if showActionBar {
                    showActionBar = false
                    targetItemID = nil
                }
            }
        )
    }

    private var dismissBackdrop: some View {
        Group {
            if showActionBar {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showActionBar = false
                        targetItemID = nil
                    }
            }
        }
    }

    private var categoryTabs: some View {
        HStack {
            let categories = StickerCategory.allCases
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                let isSelected = category == selectedCategory
                Text(category.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? Color.primary.opacity(0.1) : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
                    .onTapGesture {
                        selectedCategory = category
                        showActionBar = false
                        targetItemID = nil
                    }
                if index < categories.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder
    private func stickerCell(_ item: StickerItem) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.06))
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                    )

                if let image = item.image {
                    // 누끼/꾸미기 완료된 스티커
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 28, weight: .semibold))
                    }
                }
            }
            Text(item.title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            TapGesture().onEnded {
                if showActionBar {
                    if targetItemID == item.id { return }
                    withAnimation(.easeInOut(duration: actionBarAnimDuration)) {
                        showActionBar = false
                    }
                    let newID = item.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + actionBarAnimDuration * 0.9) {
                        targetItemID = newID
                        withAnimation(.easeInOut(duration: actionBarAnimDuration)) {
                            showActionBar = true
                        }
                    }
                } else {
                    targetItemID = item.id
                    withAnimation(.easeInOut(duration: actionBarAnimDuration)) {
                        showActionBar = true
                    }
                }
            }
        )
    }

    private var actionBar: some View {
        Group {
            if showActionBar {
                VStack(spacing: 10) {
                    Divider()
                        .padding(.horizontal, 16)
                    HStack {
                        Button {
                            showPhotoPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                Text("기존 게시물\n사진으로 만들기")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .border(Color.black, width: 1)
                        }
                        
                        Spacer()

                        Button {
                            showCamera = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "camera")
                                Text("사진 찍기")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .border(Color.black, width: 1)
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Helpers
    private func items(for category: StickerCategory) -> [StickerItem] {
        itemsByCategory[category] ?? []
    }

    private func updateItemImage(_ image: UIImage) {
        guard var arr = itemsByCategory[selectedCategory], let id = targetItemID, let index = arr.firstIndex(where: { $0.id == id }) else { return }
        var edited = arr[index]
        // TODO: 추후 "누끼 따기 (background removal)" 처리 후 결과 이미지를 대입
        edited.image = image
        arr[index] = edited
        itemsByCategory[selectedCategory] = arr
    }

    private func applySelectedImage(_ image: UIImage) {
        // 여기서 실제 누끼 처리 로직(서버/온디바이스)을 붙이면 됨.
        updateItemImage(image)
        showActionBar = false
        targetItemID = nil
    }

    private func handlePickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self), let uiImg = UIImage(data: data) {
                applySelectedImage(uiImg)
            }
        } catch {
            // 필요 시 오류 처리
        }
    }
}

#Preview {
    SitckerCollectionView()
}
