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
                    Rectangle()
                        .fill(.ddWhite)
                        .cornerRadius(8)
                        .frame(width: 75, height: 100)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 75, height: 100)
                .clipped()
                .transition(.opacity)
                .cornerRadius(8)
                .overlay(
                    Group {
                        if isFailed {
                            ZStack {
                                Rectangle()
                                    .fill(.ddGray600)
                                    .cornerRadius(8)
                                    .overlay(Image(systemName: "exclamationmark.triangle").foregroundStyle(.white))
                                    .frame(width: 75, height: 100)
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.ddBlack30)
                                
                                Text("\(day)일")
                                    .font(.subtitleSemiBold16)
                                    .foregroundStyle(.ddWhite)
                            }
                        }
                    }
                )
        }
    }
}
