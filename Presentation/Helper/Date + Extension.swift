//
//  Date + Extension.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import Foundation


extension Date {
    /// 수정된 시간을 오늘과 비교해 String으로 반환
    var timeAgo: String {
        let calender = Calendar.current
        
        let formatter = DateFormatter()
        
        if calender.isDateInToday(self) {
            formatter.dateFormat = "오늘 HH:mm"
        } else if calender.isDateInYesterday(self) {
            formatter.dateFormat = "어제 HH:mm"
        } else {
            formatter.dateFormat = "yyyy. MM. dd. a h:mm"
            formatter.amSymbol = "오전"
            formatter.pmSymbol = "오후"
        }
        
        return formatter.string(from: self)
    }
}
