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
    let pdfID: UUID = .init()
    
    var selection: PDFSelection
    var text: String
    var position: CGPoint
    var selectedLine: CGRect {
        var selectedLine: CGRect = .zero
        
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
    
    init(selection: PDFSelection, text: String, position: CGPoint) {
        self.selection = selection
        self.text = text
        self.position = position
    }
}
