//
//  MainPDFViewModel.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import PDFKit
import SwiftUI


/**
 PDFView 전체 관할 View model
 */
final class MainPDFViewModel: ObservableObject {
    
    @Published var selectedDestination: PDFDestination?
    @Published var searchSelection: PDFSelection?
    @Published var changedPageNumber: Int = 0
    @Published var selectedText: String = "" {
        didSet {
            /// 선택된 텍스트가 변경될 때 추가 작업
            updateBubbleView(selectedText: selectedText, bubblePosition: bubbleViewPosition)
            
            if isCommentVisible {
                updateCommentPosition(at: commentInputPosition)
            }
        }
    }
    
    @Published var toolMode: ToolMode = .none {
        didSet {
            updateDrawingTool()
            if isCommentVisible {
                updateCommentPosition(at: commentInputPosition)
            }
        }
    }
    
    @Published var isPaperViewFirst: Bool = true
    
    // BubbleView의 상태와 위치
    @Published var bubbleViewVisible: Bool = false
    @Published var bubbleViewPosition: CGRect = .zero
    
    // 하이라이트 색상
    @Published var selectedHighlightColor: HighlightColors = .yellow
    
    // Comment
    @Published var isCommentTapped: Bool = false {
        didSet{
            if !isCommentTapped, let comment = tappedComment {
                setHighlight(comment: comment, isTapped: false)
            }
        }
    }
    @Published var tappedComment: Comment? {
        didSet {
            if isCommentTapped, let comment = tappedComment {
                setHighlight(comment: comment, isTapped: true)
            }
        }
    }
    @Published var commentSelection: PDFSelection?
    @Published var commentInputPosition: CGPoint = .zero
    @Published var isCommentSaved: Bool = false
    
    public var document: PDFDocument?
    public var focusDocument: PDFDocument?
    
    public var focusAnnotations: [FocusAnnotation] = []
    public var figureAnnotations: [FigureAnnotation] = []       // figure 리스트
    
    public var thumnailImages: [UIImage] = []
    
    // for drawing
    public var pdfDrawer = PDFDrawer(drawingService: DrawingDataService())                          // PDFDrawer
    
    public var paperInfo: PaperInfo
    
    init(paperInfo: PaperInfo) {
        self.paperInfo = paperInfo
        
        var isStale = false
        
        if let url = try? URL.init(resolvingBookmarkData: paperInfo.url, bookmarkDataIsStale: &isStale),
        url.startAccessingSecurityScopedResource() {
            self.document = PDFDocument(url: url)
            url.stopAccessingSecurityScopedResource()
        }
    }
}


// MARK: - 초기 세팅 메소드
extension MainPDFViewModel {
    public func setPDFDocument(url: URL) {
        self.document = PDFDocument(url: url)
    }
    
    // TODO: 네트워크 연결 확인 필요, 진행도 알려줘야함, 진행 후 데이터 저장 필요
    public func fetchFocusAnnotations() async {
        guard let page = self.document?.page(at: 0) else {
            return
        }
        
        let width = page.bounds(for: .mediaBox).width
        let height = page.bounds(for: .mediaBox).height
        
        var isStale = false
        
        guard let url = try? URL.init(resolvingBookmarkData: self.paperInfo.url, bookmarkDataIsStale: &isStale),
              url.startAccessingSecurityScopedResource() else {
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let input: PDFLayout = try await NetworkManager.fetchPDFExtraction(process: .processFulltextDocument, pdfURL: url)
            
            self.focusAnnotations = NetworkManager.filterData(input: input, pageWidth: width, pageHeight: height)
            self.figureAnnotations = NetworkManager.filterFigure(input: input, pageWidth: width, pageHeight: height)
            
            print("end network connect")
        } catch {
            print(String(describing: error))
        }
    }
    
    // 텍스트 PDF 붙이는 함수
    public func setFocusDocument() {
        
        let document = PDFDocument()
        
        var pageIndex = 0

        self.focusAnnotations.forEach { annotation in
            guard let page = self.document?.page(at: annotation.page - 1)?.copy() as? PDFPage else {
                return
            }
            
            let original = page.bounds(for: .mediaBox)
            let croppedRect = original.intersection(annotation.position)
            
            page.setBounds(croppedRect, for: .mediaBox)
            document.insert(page, at: pageIndex)
            pageIndex += 1
        }
        
        self.focusDocument = document
    }
}

/// Sample 메소드
extension MainPDFViewModel {
    
    public func fetchSampleFocusAnnotations() {
        guard let page = self.document?.page(at: 0) else {
            return
        }
        let input = try! NetworkManager.getSamplePDFData()
        
        let width = page.bounds(for: .mediaBox).width
        let height = page.bounds(for: .mediaBox).height
        
        self.focusAnnotations = NetworkManager.filterData(input: input, pageWidth: width, pageHeight: height)
        self.figureAnnotations = NetworkManager.filterFigure(input: input, pageWidth: width, pageHeight: height)
    }
}

// MARK: - 뷰 상호작용 메소드

/**
 원본 보기 뷰 관련
 */
extension MainPDFViewModel {
    /// Destination의 페이지 넘버 찾는 메소드
    private func findPageNum(destination: PDFDestination?) -> Int {
        guard let page = destination?.page else {
            return -1
        }
        
        guard let num = self.document?.index(for: page) else {
            return -1
        }
        
        return num
    }
    
    /// 집중 모드에서 페이지 넘버 찾는 메소드
    public func findFocusPageNum(destination: PDFDestination?) -> PDFPage? {
        let num = self.findPageNum(destination: destination)
        
        guard let resultNum = self.focusAnnotations.firstIndex(where:{ $0.page == num + 1 }) else {
            return nil
        }
        
        let page = self.focusDocument?.page(at: resultNum)
        
        return page
    }
}

/**
 PageListView 관련
 */
extension MainPDFViewModel {
    /// 현재 document 에서 썸네일 이미지 가져오는 메소드
    public func fetchThumbnailImage() {
        var images = [UIImage]()
        
        guard let document = self.document else { return }
        
        for i in 0 ..< document.pageCount {
            if let page = document.page(at: i) {
                
                let height = page.bounds(for: .mediaBox).height
                let width = page.bounds(for: .mediaBox).width
                
                let image = page.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
                images.append(image)
            }
        }
        
        self.thumnailImages = images
    }
    
    /// 페이지 리스트 뷰에서 PDFDestination 생성 메소드
    public func goToPage(at num: Int) {
        guard let page = self.document?.page(at: num) else { return }
        
        let destination = PDFDestination(page: page, at: .zero)
        DispatchQueue.main.async {
            self.selectedDestination = destination
        }
    }
}

/**
 Figure 모아보기 뷰 관련
 */
extension MainPDFViewModel {
    /// img 파일에서 크롭 후 pdfDocument 형태로 저장하는 함수
    public func setFigureDocument(for index: Int) -> PDFDocument? {
        
        // 인덱스가 유효한지 확인
        guard index >= 0 && index < self.figureAnnotations.count else {
            print("Invalid index")
            return nil
        }
        
        let document = PDFDocument()                                    // 새 PDFDocument 생성
        let annotation = self.figureAnnotations[index]                  // 주어진 인덱스의 annotation 가져오기
        
        // 해당 페이지 가져오기
        guard let page = self.document?.page(at: annotation.page - 1)?.copy() as? PDFPage else {
            print("Failed to get page")
            return nil
        }
        
        figureAnnotations.sort { $0.page < $1.page }                    // figure와 table 페이지 순서 정렬
        
        let original = page.bounds(for: .mediaBox)                      // 원본 페이지의 bounds 가져오기
        let croppedRect = original.intersection(annotation.position)    // 크롭 영역 계산 (교차 영역)
        
        page.setBounds(croppedRect, for: .mediaBox)                     // 페이지의 bounds 설정
        document.insert(page, at: 0)                                    // 새 document에 페이지 추가
        
        return document                                                 // 생성된 PDFDocument 변환
    }
}

extension MainPDFViewModel {
    public var isBubbleViewVisible: Bool {
        get {
            self.toolMode == .translate && self.bubbleViewVisible && !self.selectedText.isEmpty
        }
    }
    

    // 선택된 텍스트가 있을 경우 BubbleView를 보이게 하고 위치를 업데이트하는 메서드
    public func updateBubbleView(selectedText: String, bubblePosition: CGRect) {
        
        // 선택된 텍스트가 있을 경우 BubbleView를 보이게 하고 위치를 업데이트
        if !selectedText.isEmpty {
            bubbleViewVisible = true
            self.bubbleViewPosition = bubblePosition
        } else {
            bubbleViewVisible = false
        }
    }
}


extension MainPDFViewModel {
    // 하이라이트 기능
    func highlightText(in pdfView: PDFView, with color: HighlightColors) {
        // toolMode가 highlight일때 동작
        guard toolMode == .highlight else { return }

        // PDFView 안에서 스크롤 영역 파악
        guard let currentSelection = pdfView.currentSelection else { return }

        // 선택된 텍스트를 줄 단위로 나눔
        let selections = currentSelection.selectionsByLine()

        guard let page = selections.first?.pages.first else { return }

        let highlightColor = color.uiColor

        selections.forEach { selection in
            var bounds = selection.bounds(for: page)
            let originBoundsHeight = bounds.size.height
            bounds.size.height *= 0.6                                                   // bounds 높이 조정하기
            bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2            // 줄인 높인만큼 y축 이동

            let highlight = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
            highlight.endLineStyle = .none
            highlight.color = highlightColor

            page.addAnnotation(highlight)
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
    public func setHighlight(comment: Comment, isTapped: Bool) {
        
        if isTapped == true {
            let selections = comment.selection.selectionsByLine()
            for lineSelection in selections {
                for page in lineSelection.pages {
                    var bounds = lineSelection.bounds(for: page)
                    
                    /// 하이라이트 높이 조정
                    let originalBoundsHeight = bounds.size.height
                    bounds.size.height *= 0.6
                    bounds.origin.y += (originalBoundsHeight - bounds.size.height) / 2
                    
                    let highlight = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
                    highlight.color = UIColor.comment
                    
                    /// 하이라이트 주석 구별하기
                    highlight.setValue("\(comment.ButtonID) isHighlight", forAnnotationKey: .contents)
                    page.addAnnotation(highlight)
                }
            }
        } else {
            for page in comment.selection.pages {
                for annotation in page.annotations {
                    /// 하이라이트 주석만 제거
                    if let annotationValue = annotation.value(forAnnotationKey: .contents) as? String,
                       annotationValue == "\(comment.ButtonID) isHighlight" {
                        page.removeAnnotation(annotation)
                    }
                }
            }
        }
    }
}


enum ToolMode {
    case none
    case translate
    case pencil
    case eraser
    case highlight
    case comment
}

extension MainPDFViewModel {
    private func updateDrawingTool() {
        switch toolMode {
        case .pencil:
            pdfDrawer.drawingTool = .pencil
        case .eraser:
            pdfDrawer.drawingTool = .eraser
        default:
            pdfDrawer.drawingTool = .none
        }
    }
}
