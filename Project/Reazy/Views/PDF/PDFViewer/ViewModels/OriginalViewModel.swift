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
    }
    
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
    
    /// Destination의 페이지 넘버 찾는 메소드
    private func findPageNum(destination: PDFDestination?) -> Int {
        guard let page = destination?.page else {
            return -1
        }
        
        guard let num = self.document?.index(for: page) else {
            return -1
        }
        
        return num
    }
    
    /// 집중 모드에서 
    public func findFocusPageNum(destination: PDFDestination?) -> PDFPage? {
        let num = self.findPageNum(destination: destination)
        print(num)
        
        guard let resultNum = self.focusAnnotations.firstIndex(where:{ $0.page == num + 1 }) else {
            return nil
        }
        
        let page = self.focusDocument?.page(at: resultNum)
        
        return page
    }
}

