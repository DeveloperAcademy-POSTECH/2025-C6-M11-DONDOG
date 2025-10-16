//
//  StickerSheetView.swift
//  DonDog-iOS
//
//  Created by 문창재 on 10/16/25.
//

import SwiftUI

struct StickerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let stickerImage: UIImage?
    
    var body: some View {
        if let stickerImage = stickerImage {
            VStack(spacing: 20) {
                Text("스티커를 붙여보세요")
                    .font(.bodyRegular16)
                    .foregroundColor(.ddGray600)
                VStack(spacing: 8){
                    HStack(spacing: 40) {
                        Button(action: {
                            dismiss()
                        }) {
                            StickerContainerView(stickerImage: stickerImage)
                        }

                        Button(action: {
                            dismiss()
                        }) {
                            StickerContainerView(stickerImage: stickerImage)
                            
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            StickerContainerView(stickerImage: stickerImage)
                        }
                    }
                    HStack(spacing: 40) {
                        Button(action: {
                            dismiss()
                        }) {
                            StickerContainerView(stickerImage: stickerImage)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            StickerContainerView(stickerImage: stickerImage)
                        }
                    }
                }
                
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .frame(height: 200)
            .background(Color.ddWhite)
        }
    }
}

struct StickerContainerView: View {
    let stickerImage: UIImage
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: stickerImage.addBorder(thickness: 8, color: .ddAlert)!)
            
            Text("하트")
                .font(.captionRegular11)
                .foregroundColor(.ddGray600)
        }
        
    }
}



#Preview {
    StickerSheetView(stickerImage: UIImage(named: "stickerTest")!)
}
