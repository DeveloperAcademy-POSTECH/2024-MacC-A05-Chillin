//
//  MainPDFViewModel.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation
import PDFKit

/**
 PDFView 전체 관할 View model
 */


final class OriginalViewModel: ObservableObject {
    @Published var selectedDestination: PDFDestination?
    
    public var document: PDFDocument?
    public var focusDocument: PDFDocument?
    
    public var focusAnnotations: [FocusAnnotation] = []
    public var figureAnnotations: [FigureAnnotation] = []       // figure 리스트
}


// MARK: - 뷰 액션 메소드들
extension OriginalViewModel {
    public func setPDFDocument(url: URL) {
        self.document = PDFDocument(url: url)
    }
    
    public func fetchFocusAnnotations() {
        guard let page = self.document?.page(at: 0) else {
            return
        }
        let input = try! NetworkManager.getSamplePDFData()
        
        let width = page.bounds(for: .mediaBox).width
        let height = page.bounds(for: .mediaBox).height
        
        self.focusAnnotations = NetworkManager.filterSampleData(input: input, pageWidth: width, pageHeight: height)
        self.figureAnnotations = NetworkManager.filterSampleFigure(input: input, pageWidth: width, pageHeight: height)
    }
    
    // 텍스트 PDF 붙이는 함수
    public func setFocusDocument() {
        
        let document = PDFDocument()
        
        var pageIndex = 0

        self.focusAnnotations.forEach { annotation in
            guard let page = self.document?.page(at: annotation.page - 1)?.copy() as? PDFPage else {
                return
            }
            
            let original = page.bounds(for: .mediaBox)
            let croppedRect = original.intersection(annotation.position)
            
            page.setBounds(croppedRect, for: .mediaBox)
            document.insert(page, at: pageIndex)
            pageIndex += 1
        }
        
        self.focusDocument = document
    }
    
    // img 파일에서 크롭 후 pdfDocument 형태로 저장하는 함수
    public func setFigureDocument(for index: Int) -> PDFDocument? {

        // 인덱스가 유효한지 확인
        guard index >= 0 && index < self.figureAnnotations.count else {
            print("Invalid index")
            return nil
        }

        let document = PDFDocument()                                    // 새 PDFDocument 생성
        let annotation = self.figureAnnotations[index]                  // 주어진 인덱스의 annotation 가져오기

        // 해당 페이지 가져오기
        guard let page = self.document?.page(at: annotation.page - 1)?.copy() as? PDFPage else {
            print("Failed to get page")
            return nil
        }

        let original = page.bounds(for: .mediaBox)                      // 원본 페이지의 bounds 가져오기
        let croppedRect = original.intersection(annotation.position)    // 크롭 영역 계산 (교차 영역)
        
        page.setBounds(croppedRect, for: .mediaBox)                     // 페이지의 bounds 설정
        document.insert(page, at: 0)                                    // 새 document에 페이지 추가
        
        return document                                                 // 생성된 PDFDocument 변환
    }
}

