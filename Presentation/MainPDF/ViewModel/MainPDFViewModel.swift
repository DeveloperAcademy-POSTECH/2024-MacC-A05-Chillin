//
//  MainPDFViewModel.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import PDFKit
import SwiftUI
import Combine


enum MainPDFViewStatus: Hashable {
    case main
    
    /// 좌측 버튼 기능
    case search
    case menu(MenuItem)
    case concentrate
    
    /// 센터 버튼 기능
    case tool(ToolItem)
    case translation
    case comment
    case capture
    
    /// 우측 버튼 기능
    case figure
    case collection
    case detail
    
    
    enum MenuItem: Hashable {
        case index
        case page
        case annotation
    }
    
    enum ToolItem: Hashable {
        case none
        case highlight
        case pencil
        case eraser
    }
}
/**
 PDFView 전체 관할 View model
 */
final class MainPDFViewModel: ObservableObject {
    let useCase: BasicPaperCRUDUseCase
    
    
    @Published public var mainPDFViewAction: MainPDFViewAction = .none
    @Published public var statusStack: Set<MainPDFViewStatus> = []
    
    @Published public var pdfOriginalViewScaleFactor: CGFloat?
    @Published public var pdfFocusViewScaleFactor: CGFloat?
    
    private let figureCapturePublisher = NotificationCenter.default.publisher(for: .isFigureCaptured)
    private let collectionCapturePublisher = NotificationCenter.default.publisher(for: .isCollectionCaptured)
    
    // MARK: - 일반 뷰 변수
    
    @Published public var dragAmount: CGPoint?
    @Published public var dragOffset: CGSize = .zero

    @Published var selectedText: String = "" {
        didSet {
            /// 선택된 텍스트가 변경될 때 추가 작업
            if isCommentVisible {
                updateCommentPosition(at: commentInputPosition)
            }
        }
    }
    // MARK: - 드로잉 관련
    
    public lazy var pdfDrawer: PDFDrawer = .init(mainPDFViewModel: self)
    
    @Published var previousTool: DrawingTool?
    @Published var selectedPenColor: PenColors?
    @Published var selectedHighlightColor: HighlightColors?
    @Published var tempPenColor: PenColors?
    @Published var tempHighlightColor: HighlightColors?
    
    // 현재 undo와 redo 가능 여부
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    // MARK: - 코멘트 관련
    
    // Comment
    @Published var isCommentTapped: Bool = false
    @Published var selectedComments: [Comment] = []
    
    @Published var commentSelection: PDFSelection?
    @Published var commentInputPosition: CGPoint = .zero
    @Published var isCommentSaved: Bool = false
    
    @Published var isSelectedEditMenuComment: Bool = false {
        didSet {
            if isCommentVisible {
                updateCommentPosition(at: commentInputPosition)
            }
        }
    }
    
    // MARK: - 폴더 관련
    
    @Published public var createMovingFolder: Bool = false
    @Published public var moveToFolderID: UUID?
    
    // MARK: - 나머지
    
    public var pdfSharedData: PDFSharedData = .shared
    private var cancellables = Set<AnyCancellable>()
    
    init(basicPaperCRUDUseCase: BasicPaperCRUDUseCase) {
        self.useCase = basicPaperCRUDUseCase
        pdfDrawer.onHistoryChange = { [weak self] in
            self?.updateUndoRedoState()
        }
        self.setBindings()
    }
    
    deinit {
        self.cancellables.forEach { $0.cancel() }
    }
}


// MARK: - 초기 세팅 메소드
extension MainPDFViewModel {
    public func savePDF(pdfView: PDFView) throws {
        var a = false
        guard let document = pdfView.document else { return }
        // TODO: 이름 변경시에 URL도 바뀌어야 하는게 아닌가?
        guard let pdfURL = PDFSharedData.shared.paperInfo?.url, let url = try? URL(resolvingBookmarkData: pdfURL, bookmarkDataIsStale: &a) else {
            print("PDF URL을 찾을 수 없습니다.")
            throw HomeViewError.cannotCreateBookmark
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
            try pdfData?.write(to: url)
            
            print("PDF 저장이 완료되었습니다.")
        } catch {
            print("PDF 저장 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    public func setBindings() {
        self.$statusStack
            .sink { [weak self] statusStack in
                if !statusStack.isToolSelected {
                    self?.selectedPenColor = nil
                    self?.selectedHighlightColor = nil
                }
            }
            .store(in: &cancellables)
        
        // 하이라이트 기능 실행
        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
            .debounce(for: .milliseconds(700), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if self.pdfDrawer.pdfView == nil { return }
                    self.highlightText(in: self.pdfDrawer.pdfView, with: self.selectedHighlightColor ?? .yellow)
                }
            }
            .store(in: &cancellables)
        
        self.figureCapturePublisher
            .sink { [weak self] _ in
                self?.statusStack.captureOff()
            }
            .store(in: &self.cancellables)
        
        self.collectionCapturePublisher
            .sink { [weak self] _ in
                self?.statusStack.captureOff()
            }
            .store(in: &self.cancellables)
        
    }
}

// MARK: - 뷰 상호작용 메소드

extension MainPDFViewModel {

    // toolMode에서 하이라이트 기능
    func highlightText(in pdfView: PDFView, with color: HighlightColors) {
        guard self.statusStack.isHighlightSelected else { return }
        highlightUIMenu(in: pdfView, with: color)
    }
    
    // UIMenu에서 하이라이트 기능
    func highlightUIMenu(in pdfView: PDFView, with color: HighlightColors) {
        guard let currentSelection = pdfView.currentSelection else { return }                   // PDFView 안에서 스크롤 영역 파악
        let selections = currentSelection.selectionsByLine()                                    // 선택된 텍스트 줄 단위로 나누기
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
                bounds.size.height *= 0.8
                bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2
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
    
    public func renameTitleCancelButtonTapped() {
        self.mainPDFViewAction = .none
    }
    
    public func renameTitleOKButtonTapped(paperInfo: PaperInfo, title: String) {
        var modifiedPaperInfo = paperInfo
        modifiedPaperInfo.title = title
        let result = self.useCase.editPDF(modifiedPaperInfo)
        
        switch result {
        case .success:
            PDFSharedData.shared.paperInfo?.title = title
            self.mainPDFViewAction = .none
        case .failure(let error):
            self.mainPDFViewAction = .duplicatedTitleAlert
            print(error)
        }
    }
}


/**
 코멘트 관련
 */

extension MainPDFViewModel {
    
    public var isCommentVisible: Bool {
        return (self.statusStack.isCommentSelected && !self.selectedText.isEmpty) || (self.isSelectedEditMenuComment && !self.selectedText.isEmpty) || self.isCommentTapped
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


// MARK: - 펜슬 툴 바 관련

extension MainPDFViewModel {
    public func highlightButtonTapped() {
        self.statusStack.highlightToggle()
        
        if self.selectedHighlightColor == nil {
            // TODO: GA 하이라이트 사용
            self.selectedHighlightColor = .yellow
            
            self.sendHighlightEventToGA(.yellow)
        } else {
            self.selectedHighlightColor = nil
        }
        
        self.selectedPenColor = nil
    }
    
    public func highlightColorButtonTapped(_ color: HighlightColors) {
        // TODO: GA 하이라이트 사용
        self.statusStack.onHighlight()
        self.selectedHighlightColor = color
        self.selectedPenColor = nil
        
        self.sendHighlightEventToGA(color)
    }
    
    public func pencilButtonTapped() {
        self.statusStack.togglePencil()
        
        if self.selectedPenColor == nil {
            // TODO: GA 펜슬 사용
            self.selectedPenColor = .black
            
            self.sendPencilEventToGA(.black)
        } else {
            self.selectedPenColor = nil
        }
        
        selectedHighlightColor = nil
    }
    
    public func pencilColorButtonTapped(_ color: PenColors) {
        // TODO: GA 펜슬 사용
        self.statusStack.onPencil()
        self.selectedPenColor = color
        self.selectedHighlightColor = nil
        
        self.sendPencilEventToGA(color)
    }
    
    public func eraserButtonTapped() {
        self.statusStack.onEraser()
        self.selectedHighlightColor = nil
        self.selectedPenColor = nil
    }
    
    
    func updateUndoRedoState() {
        canUndo = !pdfDrawer.annotationHistory.isEmpty
        canRedo = !pdfDrawer.redoStack.isEmpty
    }
}


// MARK: - Internal method
extension MainPDFViewModel {
    private func sendHighlightEventToGA(_ color: HighlightColors) {
        switch color {
        case .yellow:
            AnalyticsManager.sendParameterlessEvent(eventType: .highlightYellow)
        case .pink:
            AnalyticsManager.sendParameterlessEvent(eventType: .highlightPink)
        case .green:
            AnalyticsManager.sendParameterlessEvent(eventType: .highlightGreen)
        case .blue:
            AnalyticsManager.sendParameterlessEvent(eventType: .highlightBlue)
        }
    }
    
    private func sendPencilEventToGA(_ color: PenColors) {
        switch color {
        case .black:
            AnalyticsManager.sendParameterlessEvent(eventType: .pencilBlack)
        case .red:
            AnalyticsManager.sendParameterlessEvent(eventType: .pencilRed)
        case .blue:
            AnalyticsManager.sendParameterlessEvent(eventType: .pencilBlue)
        case .green:
            AnalyticsManager.sendParameterlessEvent(eventType: .pencilGreen)
        }
    }
}

enum ToolMode {
    case none
    case translate
    case comment
    case drawing
    case lasso
}
