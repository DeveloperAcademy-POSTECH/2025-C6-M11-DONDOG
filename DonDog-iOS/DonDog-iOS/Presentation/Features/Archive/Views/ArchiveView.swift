//
// ArchiveView.swift
// DonDog-iOS
//
// Created by 조유진 on 10/11/25.

import SwiftUI

enum ArchiveSegment: String, CaseIterable, Identifiable {
    case partnerArchive = "가족 사진"
    case myArchive = "내 사진"
    
    var id: String { self.rawValue }
}

struct ArchiveView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ArchiveViewModel
    @State private var showToastView = false
    
    private let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            VStack {
                VStack {
                    CustomNavigationBar(
                        leadingType: .back(action: { coordinator.pop() }),
                        centerType: .none,
                        trailingType: .setting(action: { coordinator.push(.setting) }),
                        navigationColor: .black
                    )
                    
                    // Month 이동
                    HStack(spacing: 16) {
                        Spacer()
                        
                        Button {
                            viewModel.goToPreviousMonth()
                        } label: {
                            Image(systemName: "arrowtriangle.left.fill")
                                .font(.body)
                                .frame(width: 24, height: 24)
                        }
                        
                        if !viewModel.displayMonths.isEmpty {
                            Text(DateUtils.string(from: viewModel.displayMonths[viewModel.currentMonthIndex].date, format: .month))
                                .font(.subtitleMedium20)
                        } else {
                            Text(DateUtils.string(from: Date(), format: .month))
                                .font(.subtitleMedium20)
                        }
                        
                        Button {
                            viewModel.goToNextMonth()
                        } label: {
                            Image(systemName: "arrowtriangle.right.fill")
                                .font(.body)
                                .frame(width: 24, height: 24)
                        }
                        
                        Spacer()
                    }
                    .foregroundStyle(.ddGray1000)
                }
                .padding(.horizontal, 20)
                
                // 사진 0장일 때 예외처리
                if !viewModel.isLoading {
                    if !viewModel.displayMonths.isEmpty {
                        let month = viewModel.displayMonths[viewModel.currentMonthIndex]
                        if month.days.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 57, height: 48)
                                Text("아직 사진이 없어요\n첫 게시물을 올려 볼까요?")
                                    .multilineTextAlignment(.center)
                                    .font(.bodyMedium16)
                            }
                            .foregroundStyle(.ddGray1000)
                            Spacer()
                        } else {
                            ScrollView {
                                VStack {
                                    VStack(alignment: .leading) {
                                        LazyVGrid(columns: grid, spacing: 8) {
                                            ForEach(month.days) { day in
                                                let isBlurred = DateUtils.isOver3daysSinceLastUpload() && viewModel.selectedAuthorType == .partnerArchive && day.date > (UserPairingStore.shared.lastUploadedAt ?? Date())
                                                Button {
                                                    if !isBlurred {
                                                        viewModel.moveToPost(day: day)
                                                    } else {
                                                        showToastView = true
                                                    }
                                                } label: {
                                                    ArchivePostContainer(url: day.thumbnailURL, day: day.day, date: day.date, isBlurred: isBlurred)
                                                }
                                                .hapticFeedback(.medium)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    } else {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 57, height: 48)
                            Text("게시물이 없어요")
                                .multilineTextAlignment(.center)
                                .font(.bodyMedium16)
                        }
                        .foregroundStyle(.ddGray1000)
                        Spacer()
                    }
                }
                
                Spacer()
                
                CustomSegmentedControl(
                    items: ArchiveSegment.allCases,
                    selectedItem: $viewModel.selectedAuthorType,
                    titleProvider: { $0.rawValue }
                )
                .padding(.bottom, 34)
            }
            
            if viewModel.isLoading {
                VStack(alignment: .center, spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.ddPrimaryBlue)
                    Text("로딩중...")
                        .font(.bodyMedium16)
                        .foregroundStyle(.ddPrimaryBlue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ddWhite)
                .background(
                    LinearGradient(colors: [.ddWhite, .ddSecondaryBlue], startPoint: .top, endPoint: .bottom)
                        .opacity(0.35)
                        .ignoresSafeArea()
                )
            }
            
            if showToastView {
                VStack {
                    Spacer()
                    ToastView(toastText: "게시물을 올린지 3일이 지났어요!")
                        .padding(.bottom, 114)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showToastView = false }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).animation(.spring()),
                            removal: .opacity.animation(.easeOut(duration: 0.7))
                        ))
                }
            }
        }
        .background(.ddWhite)
        .backHiddenSwipeEnabled()
        .task {
            viewModel.attach(coordinator: coordinator)
            await viewModel.fetchMonthlyArchives()
        }
    }
}
