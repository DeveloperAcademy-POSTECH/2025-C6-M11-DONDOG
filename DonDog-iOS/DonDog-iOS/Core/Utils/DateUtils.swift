//
//  DateUtils.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/9/25.
//

import Foundation

enum DateFormat: String {
    case yearMonth = "yyyy년 M월"
    case monthDay = "MM월 d일"
    case day = "d"
    case time = "HH:mm"
    case full = "MM월 d일 HH:mm"
    case dayKey = "yyyy-MM-dd"
}

final class DateUtils {
    private static var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }()
    
    // Date 타입의 값을 특정 형식의 문자열로 변환
    static func string(from date: Date, format: DateFormat) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = self.calendar.timeZone
        formatter.dateFormat = format.rawValue
        return formatter.string(from: date)
    }
    
    static func date(fromYear year: Int, month: Int, day: Int) -> Date? {
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components)
    }
    
    // Date 값에서 년, 월, 일과 같은 구성 요소들을 DateComponents 타입으로 추출
    static func components(from date: Date) -> DateComponents {
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
    
    // 같은 날의 데이터를 묶기 위해 해당 날짜 반환 (자정)
    static func startOfDay(for date: Date) -> Date {
        return calendar.startOfDay(for: date)
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
        formatter.dateFormat = DateFormat.time.rawValue
        
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
    
    static func isATime() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        return hour >= 9 && hour < 18
    }
}
