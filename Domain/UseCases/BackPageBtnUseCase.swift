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
        
        let pageHeight = page.bounds(for: .cropBox).maxY
        let rect = pdfView.convert(page.bounds(for: .cropBox), from: page)
        let pageIndex = document.index(for: page)
        
        var adjustY = rect.maxY / scaleFactor
        var newPageIndex = pageIndex
        
        let pagesToMove = Int(adjustY / pageHeight)
        
        if pagesToMove > 0 {
            newPageIndex = pageIndex - pagesToMove
            adjustY -= pageHeight * CGFloat(pagesToMove) + (15 / scaleFactor)
            
            if newPageIndex < 0 {
                newPageIndex = 0
                adjustY += pageHeight
            }
        }
        
        guard let targetPage = document.page(at: newPageIndex) else { return nil }
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
