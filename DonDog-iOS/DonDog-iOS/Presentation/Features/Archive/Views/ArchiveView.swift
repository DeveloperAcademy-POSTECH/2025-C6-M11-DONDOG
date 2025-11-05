//
// ArchiveView.swift
// DonDog-iOS
//
// Created by 조유진 on 10/11/25.

import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ArchiveViewModel
    
    private let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
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
                    HStack(spacing: 24) {
                        Spacer()
                        
                        Button {
                            viewModel.goToPreviousMonth()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body)
                                .frame(width: 24, height: 24)
                        }
                        
                        if !viewModel.displayMonths.isEmpty {
                            Text(DateUtils.string(from: viewModel.displayMonths[viewModel.currentMonthIndex].date, format: .month))
                                .font(.subtitleMedium20)
                        } else {
                            Text(DateUtils.string(from: Date(), format: .yearMonth))
                                .font(.subtitleMedium20)
                        }
                        
                        Button {
                            viewModel.goToNextMonth()
                        } label: {
                            Image(systemName: "chevron.right")
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
                                Text(viewModel.selectedAuthorType == .partnerArchive ? "가족이 사진을 올리지 않았어요" : "아직 사진을 올리지 않았어요")
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
                                                Button {
                                                    viewModel.moveToPost(day: day)
                                                } label: {
                                                    ArchivePostContainer(url: day.thumbnailURL, day: day.day)
                                                }
                                                .hapticFeedback(.medium)
                                            }
                                        }
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
                            Text(viewModel.selectedAuthorType == .partnerArchive ? "가족이 사진을 올리지 않았어요" : "아직 사진을 올리지 않았어요")
                                .multilineTextAlignment(.center)
                                .font(.bodyMedium16)
                        }
                        .foregroundStyle(.ddGray1000)
                        Spacer()
                    }
                }
                
                Spacer()
                
                CustomSegmentedControl(
                    selected: viewModel.selectedAuthorType,
                    onChange: { viewModel.selectAuthorType($0) }
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
        }
        .background(.ddWhite)
        .backHiddenSwipeEnabled()
        .task {
            viewModel.attach(coordinator: coordinator)
            await viewModel.fetchMonthlyArchives()
        }
    }
}
