//
//  CommentViewModel.swift
//  Reazy
//
//  Created by 김예림 on 10/28/24.
//

import Foundation
import PDFKit

class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    
    // 코멘트 추가
    func addComment(text: String, selection: PDFSelection, selectedText: String) {
        if text.isEmpty { return print("AddCommentFail: comment is empty")}
        
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
