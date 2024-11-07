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
    @Published var commentGroup: [CommentGroup] = []
    @Published var comments: [Comment] = []
    
    // pdfView 관련
    var pdfViewMidX: CGFloat = .zero
    @Published var pdfConvertedBounds: CGRect = .zero
    
    var commentPosition: CGPoint = .zero        /// 저장된 commentPosition
    
    // 코멘트 추가
    func addComment(text: String, fixSelection: PDFSelection) {
        
        let newComment = Comment(selection: fixSelection, text: text)
        comments.append(newComment)
        //commentGroup.append(CommentGroup(comments: comments))
        
        if let existingGroup = findCommentGroup(for: newComment.selectedLine) {
            existingGroup.comments.append(newComment)
        } else {
            let newGroup = CommentGroup(comments: [newComment])
            commentGroup.append(newGroup)
        }
        
        addCommentIcon(selection: fixSelection, newComment: newComment)
        drawUnderline(selection: fixSelection, newComment: newComment)
    }
    
    // 코멘트 삭제
    func deleteComment(selection: PDFSelection, comment: Comment) {
        comments.removeAll(where: { $0.id == comment.id })
        removeAnnotations(comment: comment)
    }
    
    // 코멘트 수정
    //    func editComment(comment: Comment, text: String) {
    //        comment.text = text
    //    }
}

//MARK: - 초기세팅
extension CommentViewModel {
    
    func setCommentPosition(selection: PDFSelection, pdfView: PDFView) {
        if let page = selection.pages.first {
            let bound = selection.bounds(for: page)
            let convertedBounds = pdfView.convert(bound, from: page)
            
            //position 설정
            let position = CGPoint(
                x: convertedBounds.midX,
                y: convertedBounds.maxY + 70
            )
            self.commentPosition = position
        }
    }
    
    func getPdfMidX(pdfView: PDFView) {
        guard let currentPage = pdfView.currentPage else { return }
        let bounds = currentPage.bounds(for: pdfView.displayBox)
        let pdfMidX = pdfView.convert(bounds, from: currentPage).midX
        
        self.pdfViewMidX = pdfMidX
    }
    
    private func findCommentGroup(for selectedLine: CGRect) -> CommentGroup? {
        for group in commentGroup {
            if let firstComment = group.comments.first,
               firstComment.selectedLine == selectedLine {
                return group
            }
        }
        return nil
    }
    
}

//MARK: - PDF Anootation관련
extension CommentViewModel {
    
    /// 버튼 추가
    private func addCommentIcon(selection: PDFSelection, newComment: Comment) {
        
        guard let page = selection.pages.first else { return }
        let lineBounds = newComment.selectedLine
        
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

