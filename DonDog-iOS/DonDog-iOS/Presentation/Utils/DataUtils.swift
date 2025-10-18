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
    
    static func formatTimeAgo(from date: Date) -> String {
            let secondsAgo = Int(Date().timeIntervalSince(date))
            
            switch secondsAgo {
            case 0..<60:
                return "지금"
            case 60..<3600:
                return "\(secondsAgo / 60)분 전"
            case 3600..<86400:
                return "\(secondsAgo / 3600)시간 전"
            default:
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.dateFormat = "MM월 dd일 HH:mm"
                return formatter.string(from: date)
            }
        }
}
