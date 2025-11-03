//
//  PhotoView.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/27/25.
//

import Kingfisher
import SwiftUI

struct PhotoView: View {
    let frontImageURL: String
    let backImageURL: String
    
    @State private var showingFront: Bool = true
    
    var body: some View {
        if let front = URL(string: frontImageURL), let back = URL(string: backImageURL) {
            ZStack {
                AsyncPhoto(url: front)
                    .opacity(showingFront ? 1.0 : 0.0)

                AsyncPhoto(url: back)
                    .opacity(showingFront ? 0.0 : 1.0)
            }
            .cornerRadius(8)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingFront.toggle()
                }
            }
        } else if let front = URL(string: frontImageURL) {
            AsyncPhoto(url: front)
        } else if let back = URL(string: backImageURL) {
            AsyncPhoto(url: back)
        }
    }
    
    private struct AsyncPhoto: View {
        let url: URL
        @State private var loadFailed: Bool = false
        
        var body: some View {
            KFImage(url)
                .placeholder {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ddGray600.opacity(0.2))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                }
                .onFailure { _ in
                    loadFailed = true
                }
                .cancelOnDisappear(true)
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(3.0/4.0, contentMode: .fit)
                .clipped()
                .cornerRadius(10)
                .overlay(alignment: .center) {
                    if loadFailed {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ddGray600)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(3.0/4.0, contentMode: .fit)
                            .overlay(Image(systemName: "photo").opacity(0.7))
                    }
                }
        }
    }
}
