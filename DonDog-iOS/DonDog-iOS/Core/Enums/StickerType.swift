//
//  StickerType.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/28/25.
//

import SwiftUI

enum StickerType: String, CaseIterable {
    case love = "사랑해"
    case cool = "멋지다"
    case what = "뭐야?"
    case angry = "화나"
    case sad = "슬퍼"
    
    var strokeColor: Color {
        switch self {
        case .love:
            return .ddFeelingPink
        case .cool:
            return .ddFeelingYellow
        case .what:
            return .ddFeelingGreen
        case .angry:
            return .ddFeelingOrange
        case .sad:
            return .ddFeelingBlue
        }
    }
    
    var stickerDecoString: String {
        switch self {
        case .love:
            return "loveSticker"
        case .cool:
            return "coolSticker"
        case .what:
            return "whatSticker"
        case .angry:
            return "angrySticker"
        case .sad:
            return "sadSticker"
        }
    }
}
