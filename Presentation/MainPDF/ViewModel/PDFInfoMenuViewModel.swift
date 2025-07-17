//
//  PDFInfoMenuViewModel.swift
//  Reazy
//
//  Created by 김예림 on 11/20/24.
//

import Foundation
import PDFKit

@MainActor
class PDFInfoMenuViewModel: ObservableObject {
    private let pdfInfoMenuUsecase: PDFInfoMenuUseCase
    
    @Published public var isActivityViewPresented: Bool = false
    
    public var fileURL: URL {
        let fileName = PDFSharedData.shared.paperInfo?.title ?? "Untitled"
        return FileManager.default.temporaryDirectory.appending(path: "\(fileName).pdf")
    }
    
    init(pdfInfoMenuUsecase: PDFInfoMenuUseCase) {
        self.pdfInfoMenuUsecase = pdfInfoMenuUsecase
    }
    
    public func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = String(localized: "오늘") + " HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = String(localized: "어제") +  " HH:mm"
            return dateFormatter.string(from: date)
        } else {
            // 이틀 전 이상의 날짜 포맷으로 반환
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy. MM. dd. a h:mm"
            dateFormatter.amSymbol = String(localized: "오전")
            dateFormatter.pmSymbol = String(localized: "오후")
            return dateFormatter.string(from: date)
        }
    }
    
    public func activityButtonTapped() {
        setTemporaryPDF()
        self.isActivityViewPresented.toggle()
    }
    
    
    private func setTemporaryPDF() {
        guard let document = PDFSharedData.shared.document?.copy() as? PDFDocument else { return }
        
        for pageIndex in 0 ..< document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // 각 페이지의 모든 주석을 반복하며 밑줄과 코멘트 아이콘 지우기
            for annotation in page.annotations {
                guard let contents = annotation.contents else { continue }
                
                // 하이라이트의 contents가 "UH|"로 시작하면 지우지 않기
                if !contents.hasPrefix("UH|") {
                    page.removeAnnotation(annotation)
                }
            }
        }
        
        // PDF 파일을 지정한 URL에 덮어쓰기 저장
        do {
            let pdfData = document.dataRepresentation()
            try pdfData?.write(to: self.fileURL)
            
            print("PDF 저장이 완료되었습니다.")
        } catch {
            print("PDF 저장 중 오류 발생: \(error.localizedDescription)")
        }
    }
}
