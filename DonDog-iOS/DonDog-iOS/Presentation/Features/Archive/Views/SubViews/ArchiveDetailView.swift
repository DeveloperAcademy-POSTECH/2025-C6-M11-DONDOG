//
//  ArchiveDetailView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/16/25.
//

import SwiftUI

struct ArchiveDetailView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject var viewModel: ArchiveDetailViewModel
    
    @State private var showDeleteAlert = false
    
    private var titleString: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.timeZone = TimeZone(identifier: "Asia/Seoul")
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt.string(from: viewModel.date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // CustomNavigationBar
            CustomNavigationBar(
                leadingType:
                        .back(
                            action: { coordinator.pop() }
                        ),
                centerType:
                        .title(title: titleString),
                trailingType:
                        .option(
                            action: { showDeleteAlert = true }
                        ),
                navigationColor: .black
            )
            
            // Indicator
            
            
            
            // Scroll View
            ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            DetailPhotoContainer(post: post)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(.ddWhite)
            
        }
        .padding(.horizontal, 20)
        .background(.ddWhite)
        .backHiddenSwipeEnabled()
    }
}

private struct DetailPhotoContainer: View {
    let post: ArchivePost
    @State private var showingFront: Bool = true
    
    var body: some View {
        VStack(alignment: .center) {
            if let front = post.frontImageURL, let back = post.backImageURL {
                ZStack {
                    AsyncPhoto(url: front)
                        .opacity(showingFront ? 1.0 : 0.0)
                        .rotation3DEffect(.degrees(showingFront ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    
                    AsyncPhoto(url: back)
                        .opacity(showingFront ? 0.0 : 1.0)
                        .rotation3DEffect(.degrees(showingFront ? -180 : 0), axis: (x: 0, y: 1, z: 0))
                }
                .cornerRadius(8)
                .padding(.vertical, 8)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showingFront.toggle()
                    }
                }
            } else if let front = post.frontImageURL {
                AsyncPhoto(url: front)
            } else if let back = post.backImageURL {
                AsyncPhoto(url: back)
            }
            
            // Caption
            VStack {
                if let cap = post.caption, !cap.isEmpty {
                    Text(cap)
                        .font(.titleBold20)
                        .foregroundStyle(.ddGray1000)
                }
                
                HStack(spacing: 4) {
                    if let author = post.authorName {
                        Text(author)
                            .font(.captionRegular13)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(timeString(from: post.createdAt))
                        .font(.captionRegular13)
                        .foregroundStyle(.ddGray500)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func timeString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.timeZone = TimeZone(identifier: "Asia/Seoul")
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}

private struct AsyncPhoto: View {
    let url: URL
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let img):
                img
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(width: 348, height: 464)
                    .clipped()
                    .cornerRadius(10)
                    .transition(.opacity)
            case .failure:
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ddGray600)
                    .frame(width: 348, height: 464)
                    .overlay(Image(systemName: "photo").opacity(0.7))
            case .empty:
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ddGray600.opacity(0.08))
                    .frame(width: 348, height: 464)
                    .overlay(ProgressView())
            @unknown default:
                Color.clear.frame(width: 348, height: 464)
            }
        }
    }
}
