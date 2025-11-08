//
//  ArchivePostContainer.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/19/25.
//

import Kingfisher
import SwiftUI

struct ArchivePostContainer: View {
    let url: URL
    let day: Int
    let date: Date
    let isBlurred: Bool
    
    @State private var isFailed = false
    
    var body: some View {
        ZStack(alignment: .center) {
            KFImage.url(url)
                .onProgress { _, _ in
                    isFailed = false
                }
                .onSuccess { _ in
                    isFailed = false
                }
                .onFailure { _ in
                    isFailed = true
                }
                .placeholder {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ddWhite)
                        .frame(width: 72, height: 96)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 96)
                .transition(.opacity)
                .blur(radius: isBlurred ? 8 : 0)
                .cornerRadius(8)
                .clipped()
                .overlay(
                    Group {
                        if isBlurred {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ddBlack30)
                                .overlay {
                                    VStack {
                                        Text("\(day)일")
                                            .font(.subtitleSemiBold16)
                                            .foregroundStyle(.ddWhite)
                                        Image(systemName: DateUtils.isATime(date: date) ? "sun.max.fill" : "moon.fill")
                                            .font(.body)
                                            .foregroundStyle(.white)
                                    }
                                }
                        } else if isFailed {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ddGray600)
                                    .overlay(Image(systemName: "exclamationmark.triangle").foregroundStyle(.white))
                                    .frame(width: 72, height: 96)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ddBlack30)
                                .overlay {
                                    VStack(alignment: .center) {
                                        Text("\(day)일")
                                            .font(.subtitleSemiBold16)
                                            .foregroundStyle(.ddWhite)
                                        
                                        Image(systemName: DateUtils.isATime(date: date) ? "sun.max.fill" : "moon.fill")
                                            .font(.body)
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                    }
                )
        }
    }
}
