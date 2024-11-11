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
    
    public var paperInfo: PaperInfo
    
    public var document: PDFDocument?
    var pdfCoordinates: CGRect = .zero
    
    @Published var comments: [Comment] = [] // 전체 코멘트 배열
    @Published var buttonGroup: [ButtonGroup] = [] // 전체 버튼 배열
    var tempCommentArray: [Comment] = []
    
    var commentService: CommentDataService
    private var buttonGroupService: ButtonGroupDataService
    
    // 해당 줄의 첫 코멘트를 생성하는 상황에 사용되는 변수
    private var newButtonId = UUID() // 새로 추가되는 버튼의 id
    private var isNewButton: Bool = true // 해당 줄의 첫 코멘트인지 확인
    
    @Published var commentPosition: CGPoint = .zero  /// 저장된 comment.bounds로부터 얻은 position
    
    //Comment Model
    @Published var selectedText: String = ""
    @Published var pages: [Int] = []
    @Published var selectedBounds: CGRect = .zero
    
    @Published var isEditMode = false
    @Published var comment: Comment?
    
    init(
        paperInfo: PaperInfo,
        commentService: CommentDataService,
        buttonGroupService: ButtonGroupDataService
    ) {
        self.paperInfo = paperInfo
        self.commentService = commentService
        self.buttonGroupService = buttonGroupService
        // MARK: - 기존에 저장된 데이터가 있다면 모델에 저장된 데이터를 추가
        switch commentService.loadCommentData(for: paperInfo.id) {
        case .success(let commentList):
            tempCommentArray = commentList
        case .failure(_):
            return
        }
        
        switch buttonGroupService.loadButtonGroup(for: paperInfo.id) {
        case .success(let buttonGroupList):
            buttonGroup = buttonGroupList
        case .failure(_):
            return
        }
    }
    
    func loadComments() {
        for comment in tempCommentArray {
            comments.append(comment)
            drawUnderline(newComment: comment)
        }
        
        for button in buttonGroup {
            drawCommentIcon(button: button)
        }
    }
    
    // 새로운 코멘트 추가하는 상황
    func addComment(text: String, selection: PDFSelection) {
        if let document = self.document {
            getSelectionPages(selection: selection, document: document)
        }
        if let text = selection.string {
            self.selectedText = text
        }
        isNewButton = true
        for group in buttonGroup {
            if group.selectedLine == getSelectedLine(selection: selection) {
                // 해당 줄에 이미 다른 코멘트가 저장되어있는 경우
                isNewButton = false
                // 기존에 존재하는 그룹의 버튼 id를 추가될 코멘트의 id로 지정
                newButtonId = group.id
                break
            }
        }
        if isNewButton {
            let newGroup = ButtonGroup(
                id: UUID(),
                page: pages[0],
                selectedLine: getSelectedLine(selection: selection),
                buttonPosition: getCommentIconPostion(selection: selection)
            )
            _ = buttonGroupService.saveButtonGroup(for: paperInfo.id, with: newGroup)
            buttonGroup.append(newGroup)
            newButtonId = newGroup.id
        }
        
        let newComment = Comment(id: UUID(),
                                 buttonId: newButtonId,
                                 text: text,
                                 selectedText: selectedText,
                                 selectionsByLine: getSelectionsByLine(selection: selection),
                                 pages: pages,
                                 bounds: selectedBounds
        )
        
        _ = commentService.saveCommentData(for: paperInfo.id, with: newComment)
        comments.append(newComment)
        drawUnderline(newComment: newComment)
        if isNewButton{
            // 방금 추가된 버튼의 아이콘을 그림
            drawCommentIcon(button: buttonGroup.last!)
        }
    }
    
    // 코멘트 삭제
    func deleteComment(commentId: UUID) {
        let comment = comments.filter { $0.id == commentId }.first! ///전체 코멘트 그룹에서 삭제할 코멘트를 찾음
        let buttonList = comments.filter { $0.buttonId == comment.buttonId } ///전체 코멘트 그룹에서 삭제할 코멘트와 같은 버튼 id를 공유하는 코멘트들 리스트 찾음
        let currentButtonId = comment.buttonId // 삭제할 코멘트의 버튼 id를 변수에 담음
        _ = commentService.deleteCommentData(for: paperInfo.id, id: commentId)
        comments.removeAll(where: { $0.id == commentId }) //전체 코멘트 그룹에서 코멘트 삭제
        
        if let document = self.document {
            guard let page = convertToPDFPage(pageIndex: comment.pages, document: document).first else { return }
            for annotation in page.annotations {
                if let annotationID = annotation.value(forAnnotationKey: .contents) as? String {
                    
                    // 마지막 버튼이었을 경우 버튼 아이콘, 밑줄 삭제
                    if buttonList.count == 1 {
                        if annotationID == comment.buttonId.uuidString || annotationID == comment.id.uuidString {
                            _ = buttonGroupService.deleteButtonGroup(for: paperInfo.id, id: currentButtonId)
                            buttonGroup.removeAll(where: { $0.id ==  currentButtonId})
                            page.removeAnnotation(annotation)
                        }
                    } else if buttonList.count > 1, annotationID == comment.id.uuidString {
                        // 버튼에 연결된 남은 코멘트 존재하면 버튼은 두고 밑줄만 삭제
                        page.removeAnnotation(annotation)
                    }
                }
            }
        }
    }
}

//MARK: - 초기세팅을 위한 메서드
extension CommentViewModel {
    
    // 저장할 라인 별 selection
    private func getSelectionsByLine(selection: PDFSelection) -> [selectionByLine] {
        var selections: [selectionByLine] = []
        
        let lineSelections = selection.selectionsByLine()
        
        for lineSelection in lineSelections {
            if let page = lineSelection.pages.first {
                let bounds = lineSelection.bounds(for: page)
                let pageIndex = document?.index(for: page) ?? -1
                selections.append(selectionByLine(page: pageIndex, bounds: bounds))
            }
        }
        return selections
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
    
    // 저장할 comment의 position 값 세팅
    func setCommentPosition(selectedComments: [Comment], pdfView: PDFView) {
        let buttonId = selectedComments.first?.buttonId
        guard let boundForComment = buttonGroup.filter({$0.id == buttonId}).first?.selectedLine else { return }
        if let document = self.document {
            guard let page = convertToPDFPage(pageIndex: selectedComments[0].pages, document: document).first else { return }
            let convertedBounds = pdfView.convert(boundForComment, from: page)
            
            let offset = CGFloat(selectedComments.count) * 50.0
            
            let position = CGPoint(
                x: convertedBounds.midX,
                y: convertedBounds.maxY + offset
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
    
    // buttonAnnotation 추가를 위한 아이콘 위치 구하기
    func getCommentIconPostion(selection: PDFSelection) -> CGRect {
        
        var iconPosition: CGRect = .zero
        let lineBounds = getSelectedLine(selection: selection)
        
        ///PDF 문서의 colum 구분
        let isLeft = lineBounds.maxX < pdfCoordinates.midX
        let isRight = lineBounds.minX >= pdfCoordinates.midX
        let isAcross = !isLeft && !isRight
        
        ///colum에 따른 commentIcon 좌표 값 설정
        if isLeft {
            iconPosition = CGRect(x: lineBounds.minX - 25, y: lineBounds.minY + 2 , width: 10, height: 10)
        } else if isRight || isAcross {
            iconPosition = CGRect(x: lineBounds.maxX + 5, y: lineBounds.minY + 2, width: 10, height: 10)
        }
        return iconPosition
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
    
    // pageIndex를 PDFPage로 변환
    func convertToPDFPage(pageIndex: [Int], document: PDFDocument) -> [PDFPage] {
        let PDFPages = pageIndex.compactMap { document.page(at: $0) }
        return PDFPages
    }
}


//MARK: - PDF Anootation관련
extension CommentViewModel {
    
    /// 버튼 추가
    func drawCommentIcon(button: ButtonGroup) {
        let PDFPage = document?.page(at: button.page)
        
        let image = UIImage(systemName: "text.bubble")
        image?.withTintColor(UIColor.point4, renderingMode: .alwaysOriginal)
        
        let commentIcon = ImageAnnotation(imageBounds: button.buttonPosition, image: image)
        
        commentIcon.widgetFieldType = .button
        commentIcon.color = .point4
        
        /// 버튼에 코멘트 정보 참조
        commentIcon.setValue(button.id.uuidString, forAnnotationKey: .contents)
        PDFPage?.addAnnotation(commentIcon)
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
    func drawUnderline(newComment: Comment) {
        for index in newComment.pages {
            guard let page = document?.page(at: index) else { continue }
            
            for selection in newComment.selectionsByLine {
                var bounds = selection.bounds
                
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
}
