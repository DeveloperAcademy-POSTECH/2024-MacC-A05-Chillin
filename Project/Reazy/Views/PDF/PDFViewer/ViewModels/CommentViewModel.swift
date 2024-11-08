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
    private var commentService: CommentDataService
    
    // pdf 관련
    @Published var pdfConvertedBounds: CGRect = .zero
    var pdfViewMidX: CGFloat = .zero
    
    var commentPosition: CGPoint = .zero        /// 저장된 commentPosition
    var commentGroup: [Comment] = []
    
    public var paperInfo: PaperInfo
    
    init(
        commentService: CommentDataService,
        paperInfo: PaperInfo
    ) {
        self.commentService = commentService
        self.paperInfo = paperInfo
        
        // MARK: - 기존에 저장된 데이터가 있다면 모델에 저장된 데이터를 추가
        switch commentService.loadCommentData(for: paperInfo.id, pdfURL: paperInfo.url) {
        case .success(let commentList):
            commentGroup = commentList
        case .failure(_):
            return
        }
    }
    
    // 코멘트 추가
    func addComment(text: String, selection: PDFSelection) {
        
        let selectedLine = getSelectedLine(selection: selection)
        let newComment = Comment(id: UUID(), buttonID: "\(selectedLine)", selection: selection, text: text, selectedLine: selectedLine)
        _ = commentService.saveCommentData(for: paperInfo.id, with: newComment)
        comments.append(newComment)
        addCommentIcon(selection: selection, newComment: newComment)
        drawUnderline(selection: selection, newComment: newComment)
    }
    
    // 코멘트 삭제
    func deleteComment(selection: PDFSelection, comment: Comment) {
        _ = commentService.deleteCommentData(for: paperInfo.id, id: comment.id)
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
    
    private func getSelectedLine(selection: PDFSelection) -> CGRect{
        var selectedLine: CGRect = .zero
        let lineSelection = selection.selectionsByLine()
        if let firstLineSelection = lineSelection.first {
            
            /// 배열 중 첫 번째 selection만 가져오기
            guard let page = firstLineSelection.pages.first else { return .zero}
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
    
    func findCommentGroup(tappedComment: Comment) {
        let group = comments.filter { $0.buttonID == tappedComment.buttonID }
        self.commentGroup = group
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
        commentIcon.setValue(newComment.buttonID, forAnnotationKey: .contents)
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
                if let annotationID = annotation.value(forAnnotationKey: .contents) as? String{
                    
                    if commentGroup.count == 1 {
                        if annotationID == comment.buttonID || annotationID == comment.id.uuidString {
                            page.removeAnnotation(annotation)
                        }
                    } else if commentGroup.count > 1, annotationID == comment.id.uuidString {
                        page.removeAnnotation(annotation)
                    }
                }
            }
        }
    }
}

