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
    var selectedLine: CGRect {
        var selectedLine: CGRect = .zero
        /// selection을 line 별로 받아와 배열에 저장
        let lineSelection = selection.selectionsByLine()
        if let firstLineSelection = lineSelection.first {
            
            /// 배열 중 첫 번째 selection만 가져오기
            guard let page = firstLineSelection.pages.first else { return .zero }
            let bounds = firstLineSelection.bounds(for: page)
            
            let centerX = bounds.origin.x + bounds.width / 2
            let centerY = bounds.origin.y + bounds.height / 2
            let centerPoint = CGPoint(x: centerX, y: centerY)
            
            if let line = page.selectionForLine(at: centerPoint) {
                let lineBounds = line.bounds(for: page)
                selectedLine = lineBounds
            }
        }
        return selectedLine
    }
    
    var position: CGPoint {
        guard let page = selection.pages.first else { return .zero }
        let bounds = selection.bounds(for: page)
        let converted = pdfView.convert(bounds, from: page)
        let commentPosition = CGPoint(
            x: converted.midX,
            y: converted.maxY + 70
        )
        return commentPosition
    }
    
    init(pdfView: PDFView, selection: PDFSelection, text: String) {
        self.pdfView = pdfView
        self.selection = selection
        self.text = text
    }
}
