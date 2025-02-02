//
//  BackPageButtonUseCase.swift
//  Reazy
//
//  Created by 김예림 on 1/31/25.
//

import PDFKit

protocol BackPageBtnUseCase {
    var pdfSharedData: PDFSharedData { get set }
    var tempDestination: PDFDestination? { get set }
    
    func updateTempDestination(_ destination: PDFDestination)
    func getTopLeadingDestination(pdfView: PDFView, scaleFactor: CGFloat) -> PDFDestination?
    func convertDestination(for destination: PDFDestination) -> PDFDestination
}

class DefaultBackPageBtnUseCase: BackPageBtnUseCase {
    public var tempDestination: PDFDestination?
    public var pdfSharedData: PDFSharedData = .shared
    
    func updateTempDestination(_ destination: PDFDestination) {
        tempDestination = destination
    }
    
    func getTopLeadingDestination(pdfView: PDFView, scaleFactor: CGFloat) -> PDFDestination? {
        guard let currentDestination = pdfView.currentDestination,
              let page = currentDestination.page,
              let document = pdfView.document else {
            return nil
        }
        
        print("⚠️현재 위치 : \(currentDestination)")
        
        let pageHeight = page.bounds(for: .cropBox).maxY
        let rect = pdfView.convert(page.bounds(for: .cropBox), from: page)
        var adjustY = rect.maxY / scaleFactor
        var pageIndex = document.index(for: page)
        
        print("⚠️scaleFactor : \(scaleFactor)")
        print("⚠️페이지 높이 : \(pageHeight)")
        print("⚠️y값 : \(adjustY)")
        print("⚠️페이지값 : \(pageIndex)")
        
            let pagesToMove = Int(adjustY / pageHeight)
            print("⚠️이동할 페이지 \(pagesToMove)")
            while pagesToMove > 0, pageIndex > 0 {
                print("⚠️ while문 실행")
                adjustY -= pageHeight * CGFloat(pagesToMove)
                pageIndex -= pagesToMove
            }
        
        guard let targetPage = document.page(at: pageIndex) else { return nil }
        print("⚠️이동 위치 : \(PDFDestination(page: targetPage, at: CGPoint(x: currentDestination.point.x, y: adjustY)))")
        return PDFDestination(page: targetPage, at: CGPoint(x: currentDestination.point.x, y: adjustY))
    }
    
    func convertDestination(for destination: PDFDestination) -> PDFDestination {
        guard let page = destination.page else { return .init() }
        
        let point = destination.point
        guard let pageNum = self.pdfSharedData.document?.index(for: page) else { return .init() }
        guard let convertPage = self.pdfSharedData.document?.page(at: pageNum) else { return .init() }
        
        return PDFDestination(page: convertPage, at: point)
    }
}
