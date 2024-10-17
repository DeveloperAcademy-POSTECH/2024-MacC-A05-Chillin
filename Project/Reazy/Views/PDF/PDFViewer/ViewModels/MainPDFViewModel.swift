//
//  MainPDFViewModel.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation
import PDFKit


final class OriginalViewModel: ObservableObject {
    
    static let shared = OriginalViewModel()
    
    var document: PDFDocument?
    
    private init() {}
    
}


extension OriginalViewModel {
    public func setPDFDocument(url: URL) {
        self.document = PDFDocument(url: url)
    }
}

