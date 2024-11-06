//
//  CommentViewModel.swift
//  Reazy
//
//  Created by 김예림 on 10/28/24.
//

import Foundation
import PDFKit
import SwiftUI

class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    var pdfViewMidX: CGFloat = .zero
    var pdfConvertedBounds: CGRect = .zero
    
    // 코멘트 추가
    func addComment(text: String, selection: PDFSelection) {
        
        /// 코멘트 배열에 저장
        let position = setCommentPosition(selection: selection)
        let newComment = Comment(selection: selection, text: text, position: position)
        comments.append(newComment)
        
        addCommentIcon(selection: selection, newComment: newComment)
        drawUnderline(selection: selection, newComment: newComment)
    }
    
    // 코멘트 삭제
    func deleteComment(selection: PDFSelection, comment: Comment) {
        comments.removeAll(where: { $0.id == comment.id })
        removeAnnotations(comment: comment)
    }
    
    // 코멘트 수정
    func editComment(comment: Comment, text: String) {
        comment.text = text
    }
}


//PDFannotation 관련
extension CommentViewModel {
    
    private func setCommentPosition(selection: PDFSelection) -> CGPoint {
        guard let page = selection.pages.first else { return .zero }
        let bounds = selection.bounds(for: page)
        let commentPosition = CGPoint(
            x: pdfConvertedBounds.midX,
            y: pdfConvertedBounds.maxY + 70
        )
        return commentPosition
    }
    
    /// 버튼 추가
    private func addCommentIcon(selection: PDFSelection, newComment: Comment) {
        
        let lineSelection = selection.selectionsByLine()
        if let firstLineSelection = lineSelection.first {
            print(firstLineSelection)
            guard let page = firstLineSelection.pages.first else { return }
            
            let bounds = firstLineSelection.bounds(for: page)
            let centerX = bounds.origin.x + bounds.width / 2
            let centerY = bounds.origin.y + bounds.height / 2
            let centerPoint = CGPoint(x: centerX, y: centerY)
            
            if let line = page.selectionForLine(at: centerPoint) {
                let lineBounds = line.bounds(for: page)
                
                ///PDF 문서의 colum 구분
                let isLeft = lineBounds.maxX < pdfViewMidX
                let isRight = lineBounds.minX >= pdfViewMidX
                let isAcross = !isLeft && !isRight
                
                var iconPosition: CGRect = .zero
                
                ///colum에 따른 commentIcon 좌표 값 설정
                if isLeft {
                    iconPosition = CGRect(x: lineBounds.minX - 25, y: lineBounds.minY + 2 , width: 20, height: 10)
                } else if isRight || isAcross {
                    iconPosition = CGRect(x: lineBounds.maxX + 5, y: lineBounds.minY + 2, width: 20, height: 10)
                }
                
                let commentIcon = PDFAnnotation(bounds: iconPosition, forType: .widget, withProperties: nil)
                commentIcon.widgetFieldType = .button
                commentIcon.backgroundColor =  UIColor(hex: "#727BC7")
                commentIcon.border?.lineWidth = .zero
                commentIcon.widgetControlType = .pushButtonControl
                
                /// 버튼에 코멘트 정보 참조
                commentIcon.setValue(newComment.id.uuidString, forAnnotationKey: .contents)
                page.addAnnotation(commentIcon)
            }
        }
    }
    
    /// 밑줄 그리기
    private func drawUnderline(selection: PDFSelection, newComment: Comment) {
        let selections = selection.selectionsByLine()
        
        for lineSelection in selections {
            for page in lineSelection.pages {
                var bounds = lineSelection.bounds(for: page)
                
                /// 밑줄 높이 조정
                let originalBoundsHeight = bounds.size.height
                bounds.size.height *= 0.6
                bounds.origin.y += (originalBoundsHeight - bounds.size.height) / 2.5
                
                let underline = PDFAnnotation(bounds: bounds, forType: .underline, withProperties: nil)
                underline.color = .gray600
                underline.border = PDFBorder()
                underline.border?.lineWidth = 1.2
                underline.border?.style = .solid
                
                underline.setValue(newComment.id.uuidString, forAnnotationKey: .contents)
                page.addAnnotation(underline)
            }
        }
    }
    
    private func removeAnnotations(comment: Comment) {
        for page in comment.selection.pages {
            for annotation in page.annotations {
                if let annotationID = annotation.value(forAnnotationKey: .contents) as? String,
                   annotationID == comment.id.uuidString {
                    page.removeAnnotation(annotation)
                }
            }
        }
    }
}
