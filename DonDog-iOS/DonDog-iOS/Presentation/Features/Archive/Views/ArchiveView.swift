//
// ArchiveView.swift
// DonDog-iOS
//
// Created by 조유진 on 10/11/25.

import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ArchiveViewModel
    private let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            // CustomNavigationBar
            
            // Header
            VStack { VStack(alignment: .leading, spacing: 6) {
                Text("폴라로이드 \(viewModel.totalPostCount)장 속에\n")
                + Text("\(viewModel.partnerNickname) 님과 \(viewModel.myNickname) 님").bold()
                + Text("의 추억이 담겨있어요")
            }
            .font(.subheadline)
            .padding(.vertical, 8)
                
                Divider().padding(.top, 6)
            }
            
            // Monthly Archive
            ForEach(viewModel.archiveMonths) { month in
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(String(format: "%d", month.year))년 \(month.month)월")
                        .font(.headline)
                        .padding(.horizontal, 4)
                    
                    LazyVGrid(columns: grid, spacing: 12) {
                        ForEach(month.days) { day in
                            Button {
                                print("\(month.year).\(month.month).\(day.day) 디테일 뷰 / postId: \(day.postId)")
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    AsyncImage(url: day.thumbnailURL) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(1, contentMode: .fill)
                                                .frame(height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                            
                                        case .failure:
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(height: 100)
                                                .cornerRadius(8)
                                                .overlay(
                                                    Image(systemName: "photo") .foregroundColor(.white.opacity(0.7))
                                                )
                                            
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 100)
                                            
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    
                                    Text("\(day.day)일")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        } .task {
            await viewModel.loadMonthlyArchives()
            await viewModel.loadPartnerNicknames()
        }
    }
}
