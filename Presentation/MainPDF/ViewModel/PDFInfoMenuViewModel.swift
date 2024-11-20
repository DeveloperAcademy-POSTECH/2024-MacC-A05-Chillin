//
//  PDFInfoMenuViewModel.swift
//  Reazy
//
//  Created by 김예림 on 11/20/24.
//

import Foundation

@MainActor
class PDFInfoMenuViewModel: ObservableObject {
    private let pdfInfoMenuUsecase: PDFInfoMenuUseCase
    
    init(pdfInfoMenuUsecase: PDFInfoMenuUseCase) {
        self.pdfInfoMenuUsecase = pdfInfoMenuUsecase
    }
    
    public func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "오늘 HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "어제 HH:mm"
            return dateFormatter.string(from: date)
        } else {
            // 이틀 전 이상의 날짜 포맷으로 반환
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy. MM. dd. a h:mm"
            dateFormatter.amSymbol = "오전"
            dateFormatter.pmSymbol = "오후"
            return dateFormatter.string(from: date)
        }
    }
    
}
