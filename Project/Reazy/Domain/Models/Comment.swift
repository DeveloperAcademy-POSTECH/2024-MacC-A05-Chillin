//
//  Comment.swift
//  Reazy
//
//  Created by 김예림 on 10/24/24.
//

import Foundation
import PDFKit

struct Comment {
    let id : UUID = .init()
    
    var selection: PDFSelection
    var text: String
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
}

class CommentGroup {
    private let ButtonID: String = "ButtonID"
    private var comments: [Comment] = []
    private var position: CGPoint = .zero
    
    private func saveCommentsArr(comment: Comment) {
        comments.append(comment)
    }
}


