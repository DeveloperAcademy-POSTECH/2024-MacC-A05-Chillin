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
    
    var pdfContent: PDFContent
    
    init(pdfContent: PDFContent) {
        self.pdfContent = .init(pdfView: PDFView())
    }
    
    // 코멘트 추가
    func addComment(text: String, selection: PDFSelection) {
        
        let pdfView = pdfContent.pdfView
        /// 코멘트 배열에 저장
        let newComment = Comment(pdfView: pdfView, selection: selection, text: text)
        comments.append(newComment)
        
        addCommentIcon(selection: selection, newComment: newComment)
        drawUnderline(selection: selection, newComment: newComment)
    }
    
    // 코멘트 삭제
    func deleteComment(comment: Comment) {
        comments.removeAll(where: { $0.id == comment.id })
    }
    
    // 코멘트 수정
    func editComment(comment: Comment, text: String) {
        comment.text = text
    }
}

extension CommentViewModel {
    
    private func addCommentIcon(selection: PDFSelection, newComment: Comment) {
        
        guard let page = selection.pages.first else { return }
        let bounds = selection.bounds(for: page)
        
        /// PDFAnnotation 버튼 생성
        let commentIconPosition = CGRect(x: bounds.midX, y: bounds.maxY + 10, width: 20, height: 20)
        let commentIcon = PDFAnnotation(bounds: commentIconPosition, forType: .widget, withProperties: nil)
        commentIcon.widgetFieldType = .button
        commentIcon.backgroundColor =  UIColor(hex: "#727BC7")
        commentIcon.border?.lineWidth = .zero
        commentIcon.widgetControlType = .pushButtonControl
        
        /// 버튼에 코멘트 정보 참조
        commentIcon.setValue(newComment.id.uuidString, forAnnotationKey: .contents)
        page.addAnnotation(commentIcon)
    }
    
    private func drawUnderline(selection: PDFSelection, newComment: Comment) {
        for page in selection.pages {
            let bounds = selection.bounds(for: page)
            
            let underline = PDFAnnotation(bounds: bounds, forType: .underline, withProperties: nil)
            underline.color = .gray600
            underline.border?.lineWidth = 1.2
            
            underline.setValue(newComment.id.uuidString, forAnnotationKey: .contents)
            page.addAnnotation(underline)
        }
    }
    
}
