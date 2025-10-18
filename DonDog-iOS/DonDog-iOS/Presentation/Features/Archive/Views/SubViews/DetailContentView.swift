//
//  DetailContentView.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/17/25.
//

import SwiftUI

struct DetailContentContainer: View {
    let post: ArchivePost
    
    var body: some View {
        VStack(alignment: .center) {
            // 폴라로이드 프레임
            VStack {
                // 사진
                DetailPhotoView(post: post)
                
                // 캡션 + 작성자
                DetailCaptionView(post: post)
 
            }
            .shadow(color: .ddBlack.opacity(0.05), radius: 2.5, x: 0, y: 3)
            
            // 댓글
            Spacer()
        }
    }
}
