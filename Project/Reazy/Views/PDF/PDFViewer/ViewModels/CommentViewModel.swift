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
    
    init(comments: [Comment]) {
        self.comments = comments
    }
    
    // 추가
    func addComment(text: String, selection: PDFSelection) {
        if text.isEmpty { return print("[AddCommentFail]:comment is empty")}
        
        /// 선택 영역이 여러 페이지에 걸쳐 있을 수 있음
        guard let page = selection.pages.first else { return }
        let rect = selection.bounds(for: page)
        let coordinates = (x: rect.origin.x, y: rect.origin.y)
        
        
        let newComment = Comment(coordinates: coordinates, text: text, isSelected: false)
        comments.append(newComment)
    }
    
    // 삭제
    func deleteComment(comment: Comment) {
        comments.removeAll(where: { $0.id == comment.id })
    }
    
    // 수정
    func editComment(comment: Comment, text: String) {
        comment.text = text
    }
}
