//
//  DataUtils.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/9/25.
//

import Foundation
import UIKit

struct DataUtils {
    static func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = format
        
        return formatter.string(from: date)
    }
    
    static func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        let seconds = Int(diff)
        let minutes = seconds / 60
        let hours = minutes / 60
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm" // 하루 이상 지나면 시간만 표시
        
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
    }
}
