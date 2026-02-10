//
//  MainPDFViewController.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import UIKit
import PDFKit
import Combine

/**
 원문 모드 ViewController
 */

final class OriginalViewController: UIViewController {
    let viewModel: MainPDFViewModel
    let commentViewModel: CommentViewModel
    
    let focusFigureViewModel: FocusFigureViewModel
    let pageListViewModel: PageListViewModel
    let searchViewModel: SearchViewModel
    let indexViewModel: IndexViewModel
    let backpageBtnViewModel: BackPageBtnViewModel
    let translationManager: TranslationManager
    
    var cancellable: Set<AnyCancellable> = []
    
    let mainPDFView: CustomPDFView = {
        let view = CustomPDFView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray200
        view.autoScales = false
        view.pageShadowsEnabled = false
        
        // for drawing
        view.displayDirection = .vertical
        view.usePageViewController(false)
        return view
    }()
    
    let labelBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray300
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.primary3.cgColor
        view.alpha = 0
        return view
    }()
    
    let pageLabelView: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "1 / \(PDFSharedData.shared.document!.pageCount)"
        view.font = UIFont(name: ReazyFontType.pretendardMediumFont, size: 16)
        view.textColor = .gray700
        view.alpha = 0
        return view
    }()
    
    var pageLabelTimer: Timer?
    
    // for drawing
    var shouldUpdatePDFScrollPosition = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUI()
        self.setData()
        self.setGestures()
        self.setBinding()
        self.focusFigureViewModel.fetchAnnotations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let scaleFactor = self.viewModel.pdfOriginalViewScaleFactor {
            DispatchQueue.main.async {
                self.mainPDFView.scaleFactor = scaleFactor
            }
        }
        
        super.viewWillAppear(animated)
    }
    
    // Editmenu 관련
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        /// web 검색 액션
        let searchWebAction = UIAction(title: String(localized: "Google Scholar 검색"), image: nil, identifier: nil) { action in
            if let selectedTextRange = self.mainPDFView.currentSelection?.string {
                let query = selectedTextRange.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "https://scholar.google.co.kr/scholar?hl=ko&as_sdt=0%2C5&q=\(query)") {
                    UIApplication.shared.open(url)
                }
            }
        } 
        
        let highlightAction = UIAction(title: String(localized: "하이라이트"), image: nil, identifier: nil) { action in
            self.viewModel.highlightUIMenu(in: self.mainPDFView, with: self.viewModel.selectedHighlightColor ?? .yellow)
        }
        
        let commentAction = UIAction(title: String(localized: "코멘트"), image: nil, identifier: nil) { action in
            // 코멘트 동작
            self.viewModel.isSelectedEditMenuComment = true
        }
        
        /// 검색 액션을 새로운 메뉴로 추가하기
        let newMenu = UIMenu(title: String(), image: nil, identifier: nil, options: .displayInline, children: [searchWebAction, highlightAction, commentAction])
        builder.insertSibling(newMenu, afterMenu: .standardEdit)
        
        if viewModel.statusStack.isCenterMenuSelected {
            builder.remove(menu: .lookup)
            builder.remove(menu: .share)
            builder.remove(menu: newMenu.identifier)
        } else {
            builder.replaceChildren(ofMenu: .lookup) { elements in
                return elements.filter { item in
                    switch (item as? UICommand)?.title.description {
                        ///translate, lookup 메뉴 들어가게
                    case "Google Scholar", "Highlight Action", "Comment Action":
                        return true
                    default:
                        return false
                    }
                }
            }
        }
    }
    
    
    init(
        viewModel: MainPDFViewModel,
        commentViewModel: CommentViewModel,
        originalViewModel: FocusFigureViewModel,
        pageListViewModel: PageListViewModel,
        searchViewModel: SearchViewModel,
        indexViewModel: IndexViewModel,
        backpageBtnViewModel: BackPageBtnViewModel,
        translationManager: TranslationManager
    ) {
        self.viewModel = viewModel
        self.commentViewModel = commentViewModel
        
        self.focusFigureViewModel = originalViewModel
        self.pageListViewModel = pageListViewModel
        self.searchViewModel = searchViewModel
        self.indexViewModel = indexViewModel
        self.backpageBtnViewModel = backpageBtnViewModel
        self.translationManager = translationManager
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.cancellable.forEach { $0.cancel() }
    }
}

// MARK: - 초기 설정
extension OriginalViewController {
    /// UI 설정
    private func setUI() {
        self.view.addSubview(self.mainPDFView)
        NSLayoutConstraint.activate([
            self.mainPDFView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.mainPDFView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.mainPDFView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.mainPDFView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        self.mainPDFView.addSubview(self.labelBackgroundView)
        NSLayoutConstraint.activate([
            self.labelBackgroundView.topAnchor.constraint(equalTo: self.mainPDFView.topAnchor, constant: 28),
            self.labelBackgroundView.trailingAnchor.constraint(equalTo: self.mainPDFView.trailingAnchor, constant: -28),
            self.labelBackgroundView.widthAnchor.constraint(equalToConstant: 72),
            self.labelBackgroundView.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        self.labelBackgroundView.addSubview(self.pageLabelView)
        NSLayoutConstraint.activate([
            self.pageLabelView.centerXAnchor.constraint(equalTo: self.labelBackgroundView.centerXAnchor),
            self.pageLabelView.centerYAnchor.constraint(equalTo: self.labelBackgroundView.centerYAnchor)
        ])
    }
    
    /// ViewModel 설정
    private func setData() {
        self.commentViewModel.document = PDFSharedData.shared.document
        self.mainPDFView.document = self.focusFigureViewModel.getDocument
        
        // pdfView midX 가져오기
        self.commentViewModel.getPDFCoordinates(pdfView: mainPDFView)
        
        // PDF 문서 로드 완료 후 드로잉 데이터 패치
        DispatchQueue.main.async {
            self.viewModel.pdfDrawer.pdfView = self.mainPDFView
            self.commentViewModel.loadComments()
        }
    }
    /// 텍스트 선택 해제
    private func cleanTextSelection() {
        self.mainPDFView.currentSelection = nil
    }
    
    private func setGestures() {
        viewModel.pdfDrawer.pdfView = self.mainPDFView
        
        // 애플 펜슬 제스처
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.isEnabled = true
        pencilInteraction.delegate = self
        self.view.addInteraction(pencilInteraction)
    }
    
    /// 데이터 Binding
    private func setBinding() {
        /// OriginalView -> FocusView Scale Factor 연동
        NotificationCenter.default.publisher(for: .PDFViewScaleChanged, object: self.mainPDFView)
            .compactMap { $0.object as? PDFView }
            .map { $0.scaleFactor }
            .sink { [weak self] scale in
                self?.viewModel.pdfFocusViewScaleFactor = scale
            }
            .store(in: &self.cancellable)

        /// FocusView -> OriginalView Scale Factor 연동
        self.viewModel.$pdfOriginalViewScaleFactor
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] scale in
                self?.mainPDFView.scaleFactor = scale
            }
            .store(in: &self.cancellable)
        
        self.pageListViewModel.$selectedDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let destination = destination else { return }
                guard let page = destination.page else { return }
                self?.mainPDFView.go(to: page)
            }
            .store(in: &self.cancellable)
        
        self.indexViewModel.$selectedDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let destination = destination,
                      let page = destination.page else { return }
                self?.mainPDFView.go(to: page)
            }
            .store(in: &self.cancellable)
        
        self.backpageBtnViewModel.$backPageDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                
                guard let destination = destination,
                      let scale = self?.backpageBtnViewModel.backScaleFactor else { return }
                
                if let pdfView = self?.mainPDFView {
                    pdfView.scaleFactor = scale
                    pdfView.go(to: destination)
                }
            }
            .store(in: &self.cancellable)
        
        
        self.searchViewModel.$searchDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchResult in
                if searchResult.0 == .zero { return }
                guard let pdfView = self?.mainPDFView else { return }
                guard let page = pdfView.document?.page(at: searchResult.1) else { return }
                
                let height = page.bounds(for: .mediaBox).height
                pdfView.scaleFactor = 3
                
                let tempX = (searchResult.0.origin.x - 50 < 0) ? 0 : searchResult.0.origin.x - 50
                let tempY = (searchResult.0.origin.y + 50 > height) ? height : searchResult.0.origin.y + 50
                
                let destination = PDFDestination(page: page, at: .init(x: tempX, y: tempY))
                
                pdfView.go(to: destination)
            }
            .store(in: &self.cancellable)
        
        self.viewModel.$statusStack
            .sink { [weak self] statusStack in
                print("First: ", statusStack)
                self?.mainPDFView.performActionFlag = statusStack.isCenterMenuSelected
                self?.updateGestureRecognizer(statusStack: statusStack)
            }
            .store(in: &self.cancellable)
        
        NotificationCenter.default.publisher(for: .PDFViewAnnotationHit)
            .sink { [weak self] notification in
                guard let self = self else { return }
                
                if let annotation = notification.userInfo?["PDFAnnotationHit"] as? PDFAnnotation {
                    if let type = annotation.type {
                        if type == "Stamp" {      // 코멘트 탭 했을 때
                            self.viewModel.isCommentTapped.toggle()
                            self.commentViewModel.isMenuTapped = false
                            
                            if self.viewModel.isCommentTapped, let buttonID = annotation.contents {
                                let splittedContents = buttonID.split(separator: "|")
                                let selectedComments = self.commentViewModel.comments.filter {
                                    $0.buttonId.uuidString == (splittedContents.count > 1 ? splittedContents.last! : splittedContents[0])
                                }
                                
                                self.viewModel.selectedComments = selectedComments
                                self.commentViewModel.setCommentPosition(selectedComments: self.viewModel.selectedComments, pdfView: self.mainPDFView)
                            }
                            self.viewModel.setHighlight(selectedComments: self.viewModel.selectedComments, isTapped: self.viewModel.isCommentTapped)
                        } else if type == "Link" {        // 링크 탭 했을 때
                            backpageBtnViewModel.backScaleFactor = mainPDFView.scaleFactor
                            backpageBtnViewModel.setDestination(pdfView: self.mainPDFView)
                            backpageBtnViewModel.delayBtnVisible(after: 0.8)
                        }
                    }
                }
            }
        .store(in: &self.cancellable)

        
        NotificationCenter.default.publisher(for: .PDFViewPageChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] noti in
                if let tempPDFView = noti.object as? PDFView, tempPDFView != self?.mainPDFView {
                    return
                }
                guard let page = self?.mainPDFView.currentPage else { return }
                if let document = PDFSharedData.shared.document {
                    let num =  PDFSharedData.shared.document?.index(for: page) ?? -1
                    
                    if (num &+ 1) < 0 { return }
                    
                    // 오버플로우 순환 연산
                    self?.pageLabelView.text = "\(num + 1) / \(document.pageCount)"
                    self?.pageListViewModel.changedPageNumber = num
                    self?.focusFigureViewModel.changedPageNumber = num
                    self?.backpageBtnViewModel.handleBtnVisible()
                    
                } else {
                    print("Document or page is nil")
                }
            }
            .store(in: &self.cancellable)
        
        // 번역 및 코멘트 기능 실행
        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                guard let selection = self.mainPDFView.currentSelection else {
                    // 선택된 텍스트가 없을 때 특정 액션
                    DispatchQueue.main.async {
                        self.viewModel.selectedText = ""
                        self.viewModel.isSelectedEditMenuComment = false
                    }
                    return
                }
                
                guard let _ = selection.string else { return }
                let lineSelections = selection.selectionsByLine()
                
                if let page = selection.pages.first {
                    // PDFSelection의 bounds 추출(CGRect)
                    let bound = selection.bounds(for: page)
                    let convertedBounds = self.mainPDFView.convert(bound, from: page)
                    
                    //comment position 설정
                    var commentX: CGFloat
                    var commentY: CGFloat = 0.0
                    
                    // x 좌표 설정
                    if convertedBounds.midX < 193 {                                         /// 코멘트뷰가 왼쪽 화면 초과
                        commentX = 193
                    } else if convertedBounds.midX > self.mainPDFView.bounds.maxX - 193 {   /// 코멘트뷰가 오른쪽 화면 초과
                        commentX = self.mainPDFView.bounds.maxX - 193
                    } else {
                        commentX = convertedBounds.midX
                    }
                    
                    // y 좌표 설정
                    /// 코멘트 뷰가 아래 화면 초과
                    if convertedBounds.maxY > self.mainPDFView.bounds.maxY - 200 && !(convertedBounds.maxX > self.mainPDFView.bounds.maxX * 0.6) {
                        commentY = convertedBounds.minY - 80
                        /// 코멘트 뷰가 두 컬럼 모두 선택일 때
                    } else {
                        if let lastLine = lineSelections.last, let lastPage = lastLine.pages.first {
                            let lastLineBounds = self.mainPDFView.convert(lastLine.bounds(for: lastPage), from: lastPage)
                            
                            /// 코멘트 뷰가 아래 화면으로 초과
                            if lastLineBounds.maxY > self.mainPDFView.bounds.maxY - 200 {
                                commentY = lastLineBounds.minY - 100
                            } else {
                                commentY = lastLineBounds.maxY + 80
                            }
                        }
                    }
                    
                    let commentPosition = CGPoint(
                        x: commentX,
                        y: commentY
                    )
                    
                    // 선택된 텍스트 가져오기
                    let selectedText = selection.string ?? ""
                    
                    // PDFPage의 좌표를 PDFView의 좌표로 변환
                    let pagePosition = self.mainPDFView.convert(bound, from: page)
                    
                    // PDFView의 좌표를 Screen의 좌표로 변환
                    let screenPosition = self.mainPDFView.convert(pagePosition, to: nil)
                    
                    DispatchQueue.main.async {
                        // ViewModel에 선택된 텍스트와 위치 업데이트
                        self.viewModel.selectedText = selectedText
                        self.translationManager.selectedText = selectedText
                        self.translationManager.translateViewPosition = screenPosition
                        self.viewModel.commentSelection = selection
                        self.viewModel.commentInputPosition = commentPosition
                        self.commentViewModel.selectedBounds = bound
                        
                    }
                }
            }
            .store(in: &self.cancellable)
        
        
        // 저장하면 currentSelection 해제
        self.viewModel.$isCommentSaved
            .sink { [weak self] isCommentSaved in
                if isCommentSaved {
                    self?.cleanTextSelection()
                }
            }
            .store(in: &self.cancellable)
        
        if let scrollView = self.mainPDFView.scrollView {
            scrollView.publisher(for: \.contentOffset)
                .sink { [weak self] offset in
                    if offset.x == 0 , offset.y == 0 {
                        return
                    }
                    
                    if self?.pageLabelTimer != nil {
                        self?.pageLabelTimer?.invalidate()
                    }
                    
                    self?.pageLabelView.alpha = 1
                    self?.labelBackgroundView.alpha = 1
                    
                    self?.pageLabelTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                        UIView.animate(withDuration: 0.5) {
                            self?.pageLabelView.alpha = 0
                            self?.labelBackgroundView.alpha = 0
                        }
                    }
                }
                .store(in: &self.cancellable)
        }
        
        NotificationCenter.default.publisher(for: .didSelectAnnotationCollection)
            .sink { [weak self] noti in
                guard let index = noti.userInfo?["index"] as? Int,
                      let page = self?.mainPDFView.document?.page(at: index) else { return }
                
                self?.mainPDFView.go(to: page)
            }
            .store(in: &self.cancellable)
    }
}


// MARK: - 탭 제스처 관련
extension OriginalViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: mainPDFView)
        
        // 버튼 annotation이 있는 위치인지 확인
        if let page = mainPDFView.page(for: location, nearest: true),
           let annotation = page.annotation(at: mainPDFView.convert(location, to: page)),
           annotation.widgetFieldType == .button {
            return true
        }
        return false
    }
    
    private func updateGestureRecognizer(statusStack: Set<MainPDFViewStatus>) {
        // 기존 제스처 인식기만 제거
        if let gestureRecognizers = self.mainPDFView.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer is DrawingGestureRecognizer {
                    self.mainPDFView.removeGestureRecognizer(recognizer)
                }
            }
        }
        let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
        
        if statusStack.isCaptureSelected {
            pdfDrawingGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.indirect.rawValue),
                NSNumber(value: UITouch.TouchType.direct.rawValue),
                NSNumber(value: UITouch.TouchType.pencil.rawValue)
            ]
        } else if statusStack.isPencilSelected || statusStack.isEraserSelected {
            pdfDrawingGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.indirect.rawValue),
                NSNumber(value: UITouch.TouchType.pencil.rawValue)
            ]
        } else {
            pdfDrawingGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.indirect.rawValue)
            ]
        }
        
        self.mainPDFView.addGestureRecognizer(pdfDrawingGestureRecognizer)
        pdfDrawingGestureRecognizer.drawingDelegate = viewModel.pdfDrawer
        viewModel.pdfDrawer.pdfView = self.mainPDFView
    }
    
}

//canPerformAction()으로 menuAction 제한
class CustomPDFView: PDFView {
    var performActionFlag: Bool = true
    
    var scrollView: UIScrollView? {
        self.subviews.first as? UIScrollView
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if performActionFlag {
            return false
        }
        
        if action == #selector(copy(_:)) {
            return true
        }
        
        return false
    }
}

// MARK: - 애플 펜슬 더블 탭 처리
extension OriginalViewController: UIPencilInteractionDelegate {
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        let statusStack = self.viewModel.statusStack
        
        if statusStack.isPencilSelected {
            switchToEraser(from: .pencil)
        } else if statusStack.isHighlightSelected {
            switchToEraser(from: .highlights)
        } else if statusStack.isEraserSelected {
            switchToPreviousTool()
        }
    }
    
    private func switchToEraser(from tool: DrawingTool) {
        self.viewModel.statusStack.onEraser()
        
        switch tool {
        case .pencil:
            self.viewModel.tempPenColor = self.viewModel.selectedPenColor ?? .black
            self.viewModel.selectedPenColor = nil
        case .highlights:
            self.viewModel.tempHighlightColor = self.viewModel.selectedHighlightColor ?? .yellow
            self.viewModel.selectedHighlightColor = nil
        default:
            break
        }
        
        self.viewModel.previousTool = tool
    }
    
    private func switchToPreviousTool() {
        guard let previousTool = self.viewModel.previousTool else { return }
        
        switch previousTool {
        case .pencil:
            self.viewModel.statusStack.onPencil()
            self.viewModel.selectedPenColor = self.viewModel.tempPenColor ?? .black
            
        case .highlights:
            self.viewModel.statusStack.onHighlight()
            self.viewModel.selectedHighlightColor = self.viewModel.tempHighlightColor ?? .yellow
            
        default:
            break
        }
    }
}
