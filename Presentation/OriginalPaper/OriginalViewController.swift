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
    private var isUpdatingScaleFromViewModel = false
    
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
    
    // Mac 캡쳐 오버레이(올가미)
    private var captureOverlayView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUI()
        self.setData()
        self.setGestures()
        self.setBinding()
        self.focusFigureViewModel.fetchAnnotations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let initialScaleFactor = self.mainPDFView.scaleFactor
        DispatchQueue.main.async {
            self.viewModel.pdfFocusViewScaleFactor = initialScaleFactor
        }
        
        super.viewWillAppear(animated)
    }
    
    // Editmenu 관련
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        if ProcessInfo.processInfo.isiOSAppOnMac, builder.system == .context {
            // AppleSilicon일 경우 커스텀 메뉴를 위한 기존 build menu 제거
            // 기본적으로 들어가는 메뉴 그룹들을 모두 제거
            builder.remove(menu: .standardEdit) // 오려두기, 복사, 붙여넣기 등
            builder.remove(menu: .text)         // 텍스트 포맷
            builder.remove(menu: .lookup)       // 찾아보기, 번역 등
            builder.remove(menu: .share)        // 공유
            return
        }
        
        /// web 검색 액션
        let searchWebAction = UIAction(title: String(localized: "Google Scholar 검색"), image: nil, identifier: nil) { action in
            AnalyticsManager.sendParameterlessEvent(eventType: .popupGoogleScholar) // GA 액션
            if let selectedTextRange = self.mainPDFView.currentSelection?.string {
                let query = selectedTextRange.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "https://scholar.google.co.kr/scholar?hl=ko&as_sdt=0%2C5&q=\(query)") {
                    UIApplication.shared.open(url)
                }
            }
        }
        
        let highlightAction = UIAction(title: String(localized: "하이라이트"), image: nil, identifier: nil) { action in
            AnalyticsManager.sendParameterlessEvent(eventType: .popupHighlight) // GA 액션
            self.viewModel.highlightUIMenu(in: self.mainPDFView, with: self.viewModel.selectedHighlightColor ?? .yellow)
        }
        
        let commentAction = UIAction(title: String(localized: "코멘트"), image: nil, identifier: nil) { action in
            AnalyticsManager.sendParameterlessEvent(eventType: .popupCommentClick) // GA 액션
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
        
        if ProcessInfo.processInfo.isiOSAppOnMac {
            // Mac에서 실행 시 PDFAnnotation 탭 제스쳐 추가
            let gesture = UITapGestureRecognizer()
            gesture.delegate = self
            self.mainPDFView.addGestureRecognizer(gesture)
            
            // textEditMenu 우클릭 제스처 추가
            self.mainPDFView.onRightClick = { [weak self] location in
                self?.handleRightClickAt(location)
            }
        }
    }
    
    private func handleRightClickAt(_ location: CGPoint) {
        guard let selection = mainPDFView.currentSelection,
              let selectedString = selection.string,
              !selectedString.isEmpty else {
            viewModel.isTextSelectionActive = false
            return
        }
        showTextEditMenu(at: location, selectedString: selectedString)
    }
    
    private func showTextEditMenu(at location: CGPoint, selectedString: String) {
        let menuWidth: CGFloat  = 85
        let menuHeight: CGFloat = 102
        let padding: CGFloat    = 12
        let offset: CGFloat     = 150
        let maxX = mainPDFView.bounds.maxX - 10
        let maxY = mainPDFView.bounds.maxY - 10
        
        var menuX = location.x
        var menuY = location.y + offset  // 클릭 지점 아래로
        
        // 화면 오른쪽 초과 방지
        if menuX + menuWidth > maxX {
            menuX = maxX - menuWidth - padding
        }
        // 화면 아래쪽 초과 방지
        if menuY + menuHeight > maxY {
            menuY = maxY - menuHeight - padding
        }
        
        viewModel.selectedText          = selectedString
        viewModel.textEditMenuPosition  = CGPoint(x: menuX, y: menuY)
        viewModel.isTextSelectionActive = true
    }
    
    /// 데이터 Binding
    private func setBinding() {
        /// OriginalView -> FocusView Scale Factor 연동
        NotificationCenter.default.publisher(for: .PDFViewScaleChanged, object: self.mainPDFView)
            .filter { [weak self] _ in self?.isUpdatingScaleFromViewModel == false }
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
                guard let self = self else { return }
                if self.mainPDFView.scaleFactor != scale {
                    self.isUpdatingScaleFromViewModel = true
                    self.mainPDFView.scaleFactor = scale
                    self.isUpdatingScaleFromViewModel = false
                }
            }
            .store(in: &self.cancellable)
        
        self.viewModel.$pdfOriginalViewPageIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pageIndex in
                guard let pageIndex = pageIndex else { return }
                self?.goTo(index: pageIndex)
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
                self?.mainPDFView.performActionFlag = statusStack.isCenterMenuSelected
                self?.updateGestureRecognizer(statusStack: statusStack)
            }
            .store(in: &self.cancellable)
        
        NotificationCenter.default.publisher(for: .PDFViewAnnotationHit, object: self.mainPDFView)
            .sink { [weak self] notification in
                if ProcessInfo.processInfo.isiOSAppOnMac { return }
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
        
        NotificationCenter.default.publisher(for: .PDFViewPageChanged, object: self.mainPDFView)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] noti in
                guard let page = self?.mainPDFView.currentPage else { return }
                if let document = PDFSharedData.shared.document {
                    let num = PDFSharedData.shared.document?.index(for: page) ?? -1
                    self?.viewModel.pdfFocusViewPageIndex = num
                    
                    if (num &+ 1) < 0 { return }
                    
                    // 오버플로우 순환 연산
                    self?.pageLabelView.text = "\(num + 1) / \(document.pageCount)"
                    self?.pageListViewModel.changedPageNumber = num
                    self?.focusFigureViewModel.changedPageNumber = num
                    self?.backpageBtnViewModel.handleBtnVisible()
                    
                } else {
                    log("Document or page is nil")
                }
            }
            .store(in: &self.cancellable)
        
        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.mainPDFView.currentSelection?.string?.isEmpty ?? true {
                    self.viewModel.selectedText = ""
                    self.viewModel.isTextSelectionActive = false
                }
            }
            .store(in: &self.cancellable)
        
        // 번역 및 코멘트 기능 실행
        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged, object: self.mainPDFView)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                guard let selection = self.mainPDFView.currentSelection else {
                    // 선택된 텍스트가 없을 때 특정 액션
                    DispatchQueue.main.async {
                        self.viewModel.selectedText = ""
                        self.viewModel.isSelectedEditMenuComment = false
                        self.viewModel.isTextSelectionActive = false
                    }
                    return
                }
                
                guard let _ = selection.string else { return }
                
                DispatchQueue.main.async {
                    self.viewModel.isTextSelectionActive = false
                }
                
                let lineSelections = selection.selectionsByLine()
                
                if let page = selection.pages.first {
                    // PDFSelection의 bounds 추출(CGRect)
                    let bound = selection.bounds(for: page)
                    let convertedBounds = self.mainPDFView.convert(bound, from: page)
                    
                    // comment position 설정
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
                    if offset.x == 0, offset.y == 0 {
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
    
    private func goTo(index: Int) {
        if let page = PDFSharedData.shared.document?.page(at: index) {
            self.mainPDFView.go(to: page)
        }
    }
}


// MARK: - 탭 제스처 관련
extension OriginalViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        
        let location = touch.location(in: mainPDFView)
        
        // annotation이 있는 위치인지 확인
        // Mac에서 실행할 시 제스쳐
        if let page = mainPDFView.page(for: location, nearest: true),
           let annotation = page.annotation(at: mainPDFView.convert(location, to: page)),
           let type = annotation.type {
            
            if type == "Link", let action = annotation.action {
                backpageBtnViewModel.backScaleFactor = mainPDFView.scaleFactor
                backpageBtnViewModel.setDestination(pdfView: self.mainPDFView)
                backpageBtnViewModel.delayBtnVisible(after: 0.8)
                
                self.mainPDFView.perform(action)
                return true
            } else if type == "Stamp" {
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
                return true
            }
        }
        return false
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    private func updateGestureRecognizer(statusStack: Set<MainPDFViewStatus>) {
        // Mac일 때는 올가미 오버레이 방식으로 처리
        if ProcessInfo.processInfo.isiOSAppOnMac {
            if statusStack.isCaptureSelected {
                showCaptureOverlay()
            } else {
                hideCaptureOverlay()
            }
            return
        }
        
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
    
    // Mac 캡쳐 오버레이 표시 - 모아보기, figure 추가용
    private func showCaptureOverlay() {
        guard captureOverlayView == nil else { return }
        guard let window = self.view.window else { return }
        
        let overlay = UIView()
        overlay.frame = window.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = true
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleMacCapturePan(_:)))
        overlay.addGestureRecognizer(pan)
        
        // 탭 제스처 추가 - 체크버튼 탭 감지용
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleMacCaptureTap(_:)))
        overlay.addGestureRecognizer(tap)
        
        window.insertSubview(overlay, at: window.subviews.count)
        self.captureOverlayView = overlay
    }

    // 탭 핸들러 추가
    @objc private func handleMacCaptureTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: mainPDFView)
        
        // 체크버튼 위치면 gestureRecognizerEnded로 넘겨서 캡쳐 실행
        if viewModel.pdfDrawer.checkButton.frame.contains(location) {
            viewModel.pdfDrawer.gestureRecognizerEnded(location)
        }
    }
    // Mac 캡쳐 오버레이 제거
    private func hideCaptureOverlay() {
        captureOverlayView?.removeFromSuperview()
        captureOverlayView = nil
    }
    
    // Mac 캡쳐 드래그 핸들러
    @objc private func handleMacCapturePan(_ gesture: UIPanGestureRecognizer) {
        // window 기준 위치를 mainPDFView 기준으로 변환
        let location = gesture.location(in: mainPDFView)
        print("overlay pan: \(gesture.state.rawValue), \(location)")
        
        switch gesture.state {
        case .began:   viewModel.pdfDrawer.gestureRecognizerBegan(location)
        case .changed: viewModel.pdfDrawer.gestureRecognizerMoved(location)
        case .ended:   viewModel.pdfDrawer.gestureRecognizerEnded(location)
        default: break
        }
    }
}

//canPerformAction()으로 menuAction 제한
class CustomPDFView: PDFView {
    var performActionFlag: Bool = true
    
    private let rightClickInterceptView = RightClickDetectorView()
    
    var onRightClick: ((CGPoint) -> Void)? {
        didSet { rightClickInterceptView.onRightClick = onRightClick }
    }
    
    var scrollView: UIScrollView? {
        self.subviews.first as? UIScrollView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if rightClickInterceptView.superview == nil {
            addSubview(rightClickInterceptView)
        }
        bringSubviewToFront(rightClickInterceptView)
        rightClickInterceptView.frame = bounds
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

// MARK: - Hotkeys
extension OriginalViewController {
    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(action: #selector(undoHotKey), input: "z", modifierFlags: .command)
        ]
    }
    
    @objc private func undoHotKey() {
        self.viewModel.pdfDrawer.undo()
    }
}


// 우클릭 감지용 뷰
final class RightClickDetectorView: UIView {
    var onRightClick: ((CGPoint) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let interaction = UIContextMenuInteraction(delegate: self)
        addInteraction(interaction)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard event?.buttonMask == .secondary else { return nil }
        return self
    }
}

extension RightClickDetectorView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        onRightClick?(location)  // 위치 반환
        return nil               // 기본 시스템 메뉴 표시 X
    }
}
