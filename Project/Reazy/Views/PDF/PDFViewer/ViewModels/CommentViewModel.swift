//
//  CommentViewModel.swift
//  Reazy
//
//  Created by 김예림 on 10/28/24.
//

import Foundation
import PDFKit
import SwiftUICore

class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    
    // 코멘트 추가
    func addComment(text: String, selection: PDFSelection, selectedText: String) {
        
        /// 선택 영역이 여러 페이지에 걸쳐 있을 수 있음
        guard let page = selection.pages.first else { return }
        let bounds = selection.bounds(for: page)
        let pageIndex = page.pageRef?.pageNumber ?? 0
        
        /// 선택 영역 좌표
        let coordinates = (x: bounds.origin.x, y: bounds.origin.y)
        let underline = (page: pageIndex, bounds: bounds)
        
        /// 코멘트 배열에 저장
        let newComment = Comment(underLine: underline, coordinates: coordinates, text: text, selectedText: selectedText, isPresent: false)
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
