//
//  DateUtils.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/9/25.
//

import Foundation
import UIKit

struct DateUtils {
    static func relativeTimeString(from date: Date, for dateFormat: String) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        let seconds = Int(diff)
        let minutes = seconds / 60
        let hours = minutes / 60
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = dateFormat
        
        if dateFormat != "MM월 dd일" {
            switch seconds {
            case 0..<60:
                return "지금"
            case 60..<3600:
                return "\(minutes)분 전"
            case 3600..<(3600 * 24):
                return "\(hours)시간 전"
            default:
                return formatter.string(from: date)
            }
        } else {
            return formatter.string(from: date)
        }
    }
}
