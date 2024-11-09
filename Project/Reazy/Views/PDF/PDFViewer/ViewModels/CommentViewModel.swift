//
//  CommentViewModel.swift
//  Reazy
//
//  Created by 김예림 on 10/28/24.
//

import Foundation
import PDFKit
import SwiftUI
import UIKit

class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    private var commentService: CommentDataService
    
    var pdfCoordinates: CGRect = .zero
    
    @Published var isTappedDelete: Bool = false
    var commentPosition: CGPoint = .zero        /// 저장된 commentPosition
    var commentGroup: [Comment] = []            /// 저장된 comment 중 같은 ButtonID인 애들 부를 때
    public var document: PDFDocument?
    var pages: [Int] = []
    
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
        
        if let document = self.document {
            getSelectionPages(selection: selection, document: document)
        }
        
        let newComment = Comment(id: UUID(), buttonID: "\(selectedLine)", selection: selection, text: text, selectedLine: selectedLine)
        _ = commentService.saveCommentData(for: paperInfo.id, with: newComment)
        comments.append(newComment)
        drawUnderline(selection: selection, newComment: newComment)
        
        findCommentGroup(comment: newComment)
        dump(commentGroup)
        
        if commentGroup.count == 1 {
            addCommentIcon(selection: selection, newComment: newComment)
        }
    }
    
    // 코멘트 삭제
    func deleteComment(comment: Comment) {
        _ = commentService.deleteCommentData(for: paperInfo.id, id: comment.id)
        comments.removeAll(where: { $0.id == comment.id })
        removeAnnotations(comment: comment)
    }
    
    // TODO : 수정 액션 추가해야 함
    func editComment(comment: Comment, text: String) {
        
    }
}

//MARK: - 초기세팅
extension CommentViewModel {
    
    // 저장할 comment의 position 값 세팅
    func setCommentPosition(selection: PDFSelection, pdfView: PDFView) {
        // Todo : selecton.pages 저장
        if let page = selection.pages.first {
            let bound = selection.bounds(for: page)
            let convertedBounds = pdfView.convert(bound, from: page)
            
            let position = CGPoint(
                x: convertedBounds.midX,
                y: convertedBounds.maxY + 70
            )
            self.commentPosition = position
        }
    }
    
    // buttonAnnotation 추가를 위한 pdfView의 좌표 값
    func getPDFCoordinates(pdfView: PDFView) {
        guard let currentPage = pdfView.currentPage else { return }
        let bounds = currentPage.bounds(for: pdfView.displayBox)
        let pdfCoordinates = pdfView.convert(bounds, from: currentPage)
        
        self.pdfCoordinates = pdfCoordinates
    }
    
    // selection이 위치하는 Line의 bounds값
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
    
    // 같은 buttonID를 공유하는 comment 찾기
    func findCommentGroup(comment: Comment) {
        let group = comments.filter { $0.buttonID == comment.buttonID }
        self.commentGroup = group
    }
    
    // selection 영역이 있는 pages를 [Int]로 반환
    func getSelectionPages(selection: PDFSelection, document: PDFDocument) {
        
        var pages: [Int] = []
        
        for page in selection.pages {
            let pageIndex = document.index(for: page)
            pages.append(pageIndex)
        }
        self.pages = pages
    }
}

//MARK: - PDF Anootation관련
extension CommentViewModel {
    
    /// 버튼 추가
    private func addCommentIcon(selection: PDFSelection, newComment: Comment) {
        
        guard let page = selection.pages.first else { return }
        let lineBounds = newComment.selectedLine
        
        ///PDF 문서의 colum 구분
        let isLeft = lineBounds.maxX < pdfCoordinates.midX
        let isRight = lineBounds.minX >= pdfCoordinates.midX
        let isAcross = !isLeft && !isRight
        
        var iconPosition: CGRect = .zero
        
        ///colum에 따른 commentIcon 좌표 값 설정
        if isLeft {
            iconPosition = CGRect(x: lineBounds.minX - 25, y: lineBounds.minY + 2 , width: 10, height: 10)
        } else if isRight || isAcross {
            iconPosition = CGRect(x: lineBounds.maxX + 5, y: lineBounds.minY + 2, width: 10, height: 10)
        }
        
        let image = UIImage(systemName: "text.bubble")
        image?.withTintColor(UIColor.point4, renderingMode: .alwaysOriginal)
        let commentIcon = ImageAnnotation(imageBounds: iconPosition, image: image)
        
        commentIcon.widgetFieldType = .button
        commentIcon.color = .point4
        
        /// 버튼에 코멘트 정보 참조
        commentIcon.setValue(newComment.buttonID, forAnnotationKey: .contents)
        page.addAnnotation(commentIcon)
    }
    
    public class ImageAnnotation: PDFAnnotation {
        
        private var _image: UIImage?
        
        // 초기화 시 이미지와 바운드 값을 받음
        public init(imageBounds: CGRect, image: UIImage?) {
            self._image = image
            super.init(bounds: imageBounds, forType: .stamp, withProperties: nil)
        }
        
        required public init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // 이미지를 그릴 때 사용하는 메서드
        override public func draw(with box: PDFDisplayBox, in context: CGContext) {
            guard (self._image?.cgImage) != nil else {
                return
            }
            
            let tintedImage = self._image?.withTintColor(UIColor.point4, renderingMode: .alwaysTemplate)
            
            // PDF 페이지에 이미지 그리기
            if let drawingBox = self.page?.bounds(for: box),
               let cgTintedImage = tintedImage?.cgImage {
                context.draw(cgTintedImage, in: self.bounds.applying(CGAffineTransform(
                    translationX: (drawingBox.origin.x) * -1.0,
                    y: (drawingBox.origin.y) * -1.0
                )))
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

