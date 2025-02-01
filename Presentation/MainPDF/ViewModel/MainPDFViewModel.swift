//
//  MainPDFViewModel.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import PDFKit
import SwiftUI
import Network


/**
 PDFView 전체 관할 View model
 */
final class MainPDFViewModel: ObservableObject {
    @Published var selectedText: String = "" {
        didSet {
            /// 선택된 텍스트가 변경될 때 추가 작업
            updateTranslationView(selectedText: selectedText, bubblePosition: translateViewPosition)
            
            if isCommentVisible {
                updateCommentPosition(at: commentInputPosition)
            }
        }
    }

    @Published var toolMode: ToolMode = .none {
        didSet {
            if isCommentVisible {
                updateCommentPosition(at: commentInputPosition)
            }
        }
    }
    
    @Published var isPaperViewFirst: Bool = true
    
    // BubbleView의 상태와 위치
    @Published var translateViewPosition: CGRect = .zero

    // Comment
    @Published var isCommentTapped: Bool = false
    @Published var selectedComments: [Comment] = []
    
    @Published var commentSelection: PDFSelection?
    @Published var commentInputPosition: CGPoint = .zero
    @Published var isCommentSaved: Bool = false
    
    // Drawing tool
    public var pdfDrawer: PDFDrawer = .init()
    @Published var isHighlight: Bool = false
    @Published var isPencil: Bool = false
    @Published var isEraser: Bool = false
    
    @Published var previousTool: DrawingTool?
    @Published var selectedPenColor: PenColors?
    @Published var selectedHighlightColor: HighlightColors?
    @Published var tempPenColor: PenColors?
    @Published var tempHighlightColor: HighlightColors?
    
    
    func toggleHighlight() {
        isHighlight.toggle()
        pdfDrawer.drawingTool = isHighlight ? .highlights : .none
    }

    func togglePencil() {
        isPencil.toggle()
        pdfDrawer.drawingTool = isPencil ? .pencil : .none
    }
    
    func toggleEraser() {
        isEraser.toggle()
        pdfDrawer.drawingTool = isEraser ? .eraser : .none
    }
    
    // 현재 undo와 redo 가능 여부
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    public var pdfSharedData: PDFSharedData = .shared
    
    @Published var isMenuSelected: Bool = false
    
    @Published public var pageNumber: Int = 0
    
    @Published public var paperInfo: PaperInfo = PDFSharedData.shared.paperInfo!
    
    @Published public var selectedButton: Buttons?
        
    init() {
        pdfDrawer.onHistoryChange = { [weak self] in
            self?.updateUndoRedoState()
        }
        
//        self.paperInfo = paperInfo
//        
//        var isStale = false
//        
//        // TODO: 경로 바뀔 시 모델에 Update 필요
//        if let url = try? URL.init(resolvingBookmarkData: paperInfo.url, bookmarkDataIsStale: &isStale),
//        url.startAccessingSecurityScopedResource() {
//            self.document = PDFDocument(url: url)
//            url.stopAccessingSecurityScopedResource()
//        } else {
//            if let id = UserDefaults.standard.value(forKey: "sampleId") as? String,
//               id == paperInfo.id.uuidString {
//                self.document = PDFDocument(url: Bundle.main.url(forResource: "Reazy Sample Paper", withExtension: "pdf")!)
//            }
//        }
    }
    
    deinit {
        print(#function)
    }
}


// MARK: - 초기 세팅 메소드
extension MainPDFViewModel {
    public func savePDF(pdfView: PDFView) {
        print("savePDF")
        guard let document = pdfView.document else { return }
        guard let pdfURL = document.documentURL else {
            print("PDF URL을 찾을 수 없습니다.")
            return
        }
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // 각 페이지의 모든 주석을 반복하며 밑줄과 코멘트 아이콘 지우기
            for annotation in page.annotations {
                if let a = annotation.contents, a.split(separator: "|")[0] != "UH" {
                    page.removeAnnotation(annotation)
                }
            }
        }
        
        // PDF 파일을 지정한 URL에 덮어쓰기 저장
        do {
            let pdfData = document.dataRepresentation()
            try pdfData?.write(to: pdfURL)
            print("PDF 저장이 완료되었습니다.")
        } catch {
            print("PDF 저장 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    // 텍스트 PDF 붙이는 함수
//    public func setFocusDocument() {
//        
//        let document = PDFDocument()
//        
//        var pageIndex = 0
//
//        self.focusAnnotations.forEach { annotation in
//            guard let page = self.document?.page(at: annotation.page - 1)?.copy() as? PDFPage else {
//                return
//            }
//            
//            let original = page.bounds(for: .mediaBox)
//            let croppedRect = original.intersection(annotation.position)
//            
//            page.setBounds(croppedRect, for: .mediaBox)
//            document.insert(page, at: pageIndex)
//            pageIndex += 1
//        }
//        
//        self.focusDocument = document
//    }
}

/// Sample 메소드
extension MainPDFViewModel {
    
//    public func fetchSampleFocusAnnotations() {
//        guard let page = self.document?.page(at: 0) else {
//            return
//        }
//        let input = try! NetworkManager.getSamplePDFData()
//        
//        self.figureAnnotations = NetworkManager.filterFigure(input: input)
//    }
}

// MARK: - 뷰 상호작용 메소드

extension MainPDFViewModel {
    public func updateTranslationView(selectedText: String, bubblePosition: CGRect) {
        // 선택된 텍스트가 있을 경우 TranslationView를 보이게 하고 위치를 업데이트
        if !selectedText.isEmpty {
            self.translateViewPosition = bubblePosition
        } 
    }
}

extension MainPDFViewModel {
    // 하이라이트 기능
    func highlightText(in pdfView: PDFView, with color: HighlightColors) {
        
        guard pdfDrawer.drawingTool == .highlights else { return }
        
        guard let currentSelection = pdfView.currentSelection else { return }               // PDFView 안에서 스크롤 영역 파악
        let selections = currentSelection.selectionsByLine()                                // 선택된 텍스트를 줄 단위로 나눔
        guard let page = selections.first?.pages.first else { return }

        let highlightColor = color.uiColor
        let id = UUID()

        selections.forEach { selection in
            
            var bounds = selection.bounds(for: page)
            let originBoundsHeight = bounds.size.height
            
            switch originBoundsHeight {
            case 18... :
                bounds.size.height *= 0.45
                bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2
            case 16..<18 :
                bounds.size.height *= 0.5
                bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2
            case 11..<16 :
                bounds.size.height *= 0.55
                bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2
            case 10..<11 :
                bounds.size.height *= 0.6
                bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2
            case 9..<10 :
                bounds.size.height *= 0.7
                bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2
            default :
                bounds.size.height *= 0.8                                                   // bounds 높이 조정하기
                bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2            // 줄인 높인만큼 y축 이동
            }

            let highlight = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
            highlight.endLineStyle = .none
            highlight.color = highlightColor
            highlight.contents = "UH|\(selection.string ?? "nil")|\(color.rawValue)|\(id)"
            
            page.addAnnotation(highlight)
            pdfDrawer.annotationHistory.append((action: .add(highlight), annotation: highlight, page: page))
        }
        
        pdfView.clearSelection()
    }
}


/**
 코멘트 관련
 */

extension MainPDFViewModel {
    
    public var isCommentVisible: Bool {
        return (self.toolMode == .comment && !self.selectedText.isEmpty) || self.isCommentTapped
    }
    
    public func updateCommentPosition(at position: CGPoint) {
        self.commentInputPosition = position
    }
    
    /// 하이라이트
    public func setHighlight(selectedComments: [Comment], isTapped: Bool) {
        if isTapped {
            for comment in selectedComments {
                for index in comment.pages {
                    guard let page = self.pdfSharedData.document?.page(at: index) else { continue }
                    
                    for selection in comment.selectionsByLine {
                        var bounds = selection.bounds
                        
                        /// 하이라이트 높이 조정
                        let originalBoundsHeight = bounds.size.height
                        
                        switch originalBoundsHeight {
                        case 18... :
                            bounds.size.height *= 0.45
                            bounds.origin.y += (originalBoundsHeight - bounds.size.height) / 2
                        case 16..<18 :
                            bounds.size.height *= 0.5
                            bounds.origin.y += (originalBoundsHeight - bounds.size.height) / 2
                        case 11..<16 :
                            bounds.size.height *= 0.55
                            bounds.origin.y += (originalBoundsHeight - bounds.size.height) / 2
                        case 10..<11 :
                            bounds.size.height *= 0.6
                            bounds.origin.y += (originalBoundsHeight - bounds.size.height) / 2
                        case 9..<10 :
                            bounds.size.height *= 0.7
                            bounds.origin.y += (originalBoundsHeight - bounds.size.height) / 2
                        default :
                            bounds.size.height *= 0.8                                                   // bounds 높이 조정하기
                            bounds.origin.y += (originalBoundsHeight - bounds.size.height) / 2            // 줄인 높인만큼 y축 이동
                        }
                        
                        let highlight = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
                        highlight.color = UIColor.comment
                        
                        /// 하이라이트 주석 구별하기
                        highlight.setValue("\(comment.buttonId) isHighlight", forAnnotationKey: .contents)
                        page.addAnnotation(highlight)
                    }
                }
            }
        } else {
            for comment in selectedComments {
                /// 하이라이트 제거
                for index in comment.pages {
                    guard let page = self.pdfSharedData.document?.page(at: index) else { continue }
                    
                    for annotation in page.annotations {
                        if let annotationValue = annotation.value(forAnnotationKey: .contents) as? String,
                           annotationValue == "\(comment.buttonId) isHighlight" {
                            page.removeAnnotation(annotation)
                        }
                    }
                }
            }
        }
    }
}

/**
 펜슬 툴 바 redo, undo 관련
 */

extension MainPDFViewModel {
    func updateUndoRedoState() {
        canUndo = !pdfDrawer.annotationHistory.isEmpty
        canRedo = !pdfDrawer.redoStack.isEmpty
    }
}

enum ToolMode {
    case none
    case translate
    case comment
    case drawing
    case lasso
}
