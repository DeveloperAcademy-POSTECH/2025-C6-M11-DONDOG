//
//  HomeEmptyView.swift
//  DonDog-iOS
//
//  Created by Ito on 11/19/25.
//

import SwiftUI

struct HomeEmptyView: View {
    let selectedPostType: ArchiveSegment
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ppGray200)
                .overlay {
                    VStack {
                        Image("HomeEmptyView")
                            .padding(.top, selectedPostType == ArchiveSegment.partnerArchive ?  0 : 2 )
                        if selectedPostType == ArchiveSegment.partnerArchive {
                            Text("가족이 아직 사진을 올리지 않았어요.")
                                .font(.subtitleSemiBold16)
                                .foregroundStyle(.ppGray700)
                            Text("조금만 기다려 주세요. 사진이 곧 찾아올 거예요.")
                                .font(.captionRegular14)
                                .foregroundStyle(.ppGray500)
                                .padding(.top, 2)
                        } else {
                            let remainingTime = DateUtils.remainingHoursForUpload()
                            Text("\(remainingTime.period) 게시물을 올릴 수 있는 시간이")
                                .multilineTextAlignment(.center)
                                .font(.subtitleSemiBold16)
                                .foregroundStyle(.ppGray700)
                            HStack(spacing: 0) {
                                Text("\(remainingTime.hours)시간")
                                    .foregroundStyle(.ppPrime)
                                Text(" 남았어요!")
                                    .foregroundStyle(.ppGray700)
                            }
                            .font(.subtitleSemiBold16)
                            .padding(.top, 2)
                        }
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
    }
}
