//
//  DetailPhotoView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/17/25.
//

import SwiftUI

struct DetailPhotoView: View {
    let post: ArchivePost
    @State private var showingFront: Bool = true
    
    var body: some View {
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
            .padding(.horizontal, 20)
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
    }
    
    // 추후 분리
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
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .clipped()
                        .cornerRadius(10)
                        .transition(.opacity)
                case .failure:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ddGray600)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .overlay(Image(systemName: "photo").opacity(0.7))
                case .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ddGray600.opacity(0.08))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .overlay(ProgressView())
                @unknown default:
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                }
            }
        }
    }
}
