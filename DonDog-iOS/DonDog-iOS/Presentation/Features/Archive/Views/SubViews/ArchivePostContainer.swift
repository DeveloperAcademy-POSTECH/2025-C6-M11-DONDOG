//
//  ArchivePostContainer.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/19/25.
//

import SwiftUI

struct ArchivePostContainer: View {
    let url: URL
    let day: Int
    
    var body: some View {
        ZStack(alignment: .center) {
            AsyncImage(url: url) { state in
                switch state {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 100)
                        .clipped()
                        .transition(.opacity)
                        .cornerRadius(8)
                        .overlay(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.ddGray1000.opacity(0.3))
                                
                                Text("\(day)일")
                                    .font(.subtitleSemiBold16)
                                    .foregroundStyle(.ddWhite)
                            }
                        )
                    
                case .failure:
                    Rectangle()
                        .fill(.ddGray600)
                        .cornerRadius(8)
                        .overlay(Image(systemName: "photo").opacity(0.7))
                        .frame(width: 75, height: 100)
                    
                case .empty:
                    Rectangle()
                        .fill(.ddGray600.opacity(0.2))
                        .cornerRadius(8)
                        .frame(width: 75, height: 100)
                    
                @unknown default:
                    Color.clear.frame(width: 75, height: 100)
                }
            }
        }
    }
}
