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
}
