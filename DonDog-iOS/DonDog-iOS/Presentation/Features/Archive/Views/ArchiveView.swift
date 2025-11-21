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
                        centerType: .title(title: "보관함"),
                        trailingType: .setting(action: { coordinator.push(.setting) }),
                        navigationColor: .black
                    )
                    .padding(.horizontal, 20)
                    
                    // Month 이동
                    HStack(spacing: 16) {
                        Spacer()
                        
                        Button {
                            viewModel.goToPreviousMonth()
                        } label: {
                            Image(viewModel.hasPreviousDisplayMonth ? "ArchiveLeftButton" : "ArchiveLeftButtonGray")
                                .frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, 10)
                        .disabled(!viewModel.hasPreviousDisplayMonth)
                        
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
                            Image(viewModel.hasNextDisplayMonth ? "ArchiveRightButton" : "ArchiveRightButtonGray")
                                .frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, 10)
                        .disabled(!viewModel.hasNextDisplayMonth)
                        
                        Spacer()
                    }
                    .foregroundStyle(.ppBlack)
                    .padding(.vertical, 23)
                    .background(.ppGray200)
                }
                
                ZStack(alignment: .bottom) {
                    // 사진 0장일 때 예외처리
                    if !viewModel.isLoading {
                        if !viewModel.displayMonths.isEmpty {
                            let month = viewModel.displayMonths[viewModel.currentMonthIndex]
                            if month.days.isEmpty {
                                Spacer()
                                VStack(spacing: 16) {
                                    Image("ArchiveEmptyView")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 160, height: 118)
                                    Text(
                                        viewModel.isCurrentMonthDisplayed
                                        ? "아직 사진이 없어요\n첫 게시물을 올려 볼까요?"
                                        : "기록이 없어요"
                                    )
                                    .multilineTextAlignment(.center)
                                    .font(.bodyMedium16)
                                }
                                .foregroundStyle(.ppGray500)
                                Spacer()
                            } else {
                                ScrollView {
                                    VStack {
                                        VStack(alignment: .leading) {
                                            LazyVGrid(columns: grid, spacing: 4) {
                                                ForEach(month.days) { day in
                                                    Button {
                                                        if !viewModel.isPostBlurred(for: day) {
                                                            viewModel.moveToPost(day: day)
                                                        } else {
                                                            showToastView = true
                                                        }
                                                    } label: {
                                                        ArchivePostContainer(url: day.thumbnailURL, day: day.day, date: day.date, isBlurred: viewModel.isPostBlurred(for: day))
                                                    }
                                                    .hapticFeedback(.medium)
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                        }
                                    }
                                    .padding(.bottom, 100)
                                }
                                .padding(.top, 20)
                            }
                        } else {
                            Spacer()
                            VStack(spacing: 16) {
                                Image("ArchiveEmptyView")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 160, height: 118)
                                Text("아직 사진이 없어요\n첫 게시물을 올려 볼까요?")
                                    .multilineTextAlignment(.center)
                                    .font(.bodyMedium16)
                            }
                            .foregroundStyle(.ppGray500)
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
            }
            
            if viewModel.isLoading {
                VStack(alignment: .center, spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.ppPrime)
                    Text("로딩중...")
                        .font(.bodyMedium16)
                        .foregroundStyle(.ppPrime)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ppWhite)
            }
            
            if showToastView {
                VStack {
                    Spacer()
                    ToastView(toastText: "게시물을 올린지 3일이 지났어요!")
                        .padding(.bottom, 101)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
        .background(.ppWhite)
        .backHiddenSwipeEnabled()
        .task {
            viewModel.attach(coordinator: coordinator)
            await viewModel.fetchMonthlyArchives()
        }
    }
}
