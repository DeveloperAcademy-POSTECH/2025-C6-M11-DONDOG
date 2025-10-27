//
//  StickerUtils.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import UIKit

struct StickerUtils {
    enum EmotionType: String, CaseIterable {
        case love = "사랑해"
        case cool = "멋지다"
        case confused = "뭐야?"
        case angry = "화나"
        case sad = "슬퍼"
        case none
    }
}

extension StickerUtils.EmotionType {
    var borderColor: UIColor {
        switch self {
        case .love: return .ddFeelingPink
        case .cool: return .ddFeelingYellow
        case .confused: return .ddFeelingGreen
        case .angry: return .ddFeelingOrange
        case .sad: return .ddFeelingBlue
        case .none: return .ddGray700
        }
    }
}
