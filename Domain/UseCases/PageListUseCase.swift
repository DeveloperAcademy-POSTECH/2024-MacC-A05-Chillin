//
//  PageListUseCase.swift
//  Reazy
//
//  Created by 문인범 on 11/16/24.
//

import UIKit
import PDFKit


protocol PageListUseCase {
    var pdfSharedData: PDFSharedData { get set }
    
    func getThumbnailImage() -> [UIImage]?
    
    func goToPage(at num: Int) -> PDFDestination
}



class DefaultPageListUseCase: PageListUseCase {
    
    var pdfSharedData: PDFSharedData = .shared
    
    public func getThumbnailImage() -> [UIImage]? {
        var images = [UIImage]()
        
        guard let document = self.pdfSharedData.document else {
            return nil
        }
        
        for i in 0 ..< document.pageCount {
            if let page = document.page(at: i) {
                
                let height = page.bounds(for: .mediaBox).height
                let width = page.bounds(for: .mediaBox).width
                
                let image = page.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
                images.append(image)
            }
        }
        
        return images
    }
    
    public func goToPage(at num: Int) -> PDFDestination {
        guard let page = self.pdfSharedData.document?.page(at: num) else {
            return .init()
        }
        
        let destination = PDFDestination(page: page, at: .zero)
        
        return destination
    }
}
