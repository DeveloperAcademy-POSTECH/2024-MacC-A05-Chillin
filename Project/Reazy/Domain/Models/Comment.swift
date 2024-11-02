//
//  Comment.swift
//  Reazy
//
//  Created by 김예림 on 10/24/24.
//

import Foundation
import PDFKit

class Comment {
    let id : UUID = .init()
    
    var pdfView: PDFView
    var selection: PDFSelection
    var text: String
    var isPresent: Bool
    
    var position: CGPoint {
        guard let page = selection.pages.first else { return .zero }
        let bounds = selection.bounds(for: page)
        let converted = pdfView.convert(bounds, from: page)
        let commentPosition = CGPoint(
            x: converted.midX,
            y: converted.midY
        )
        return commentPosition
    }
    
    init(pdfView: PDFView, selection: PDFSelection, text: String) {
        self.pdfView = pdfView
        self.selection = selection
        self.text = text
        self.isPresent = false
    }
}
