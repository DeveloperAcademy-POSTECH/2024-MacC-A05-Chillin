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
    
    let testPDFView: PDFView = {
        let view = PDFView()
        view.backgroundColor = .gray200
        view.autoScales = false
        view.pageShadowsEnabled = false
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
    }
    
    // menu 관련
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        /// web 검색 액션
        let searchWebAction = UIAction(title: "Search Web", image: nil, identifier: nil) { action in
            if let selectedTextRange = self.mainPDFView.currentSelection?.string {
                let query = selectedTextRange.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "https://www.google.com/search?q=\(query)") {
                    UIApplication.shared.open(url)
                }
            }
        }
        
        /// 검색 액션을 새로운 메뉴로 추가하기
        let newMenu = UIMenu(title: String(), image: nil, identifier: nil, options: .displayInline, children: [searchWebAction])
        builder.insertSibling(newMenu, afterMenu: .standardEdit)
        
        /// 모드에 따라 뜨는 메뉴 다르게 설정
        switch viewModel.toolMode {
        case .comment, .drawing, .translate:
            builder.remove(menu: .lookup)
            builder.remove(menu: .share)
            builder.remove(menu: newMenu.identifier)
        default :
            builder.replaceChildren(ofMenu: .lookup) { elements in
                return elements.filter { item in
                    switch (item as? UICommand)?.title.description {
                        ///translate, lookup 메뉴 들어가게
                    case "Search Web" :
                        return true
                    default:
                        return false
                    }
                }
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        // 집중모드 데이터 패치
        self.focusFigureViewModel.fetchAnnotations()
        
//        pageListViewModel.goToPage(at: viewModel.changedPageNumber)
    }
    
    init(
        viewModel: MainPDFViewModel,
        commentViewModel: CommentViewModel,
        originalViewModel: FocusFigureViewModel,
        pageListViewModel: PageListViewModel,
        searchViewModel: SearchViewModel,
        indexViewModel: IndexViewModel
    ) {
        self.viewModel = viewModel
        self.commentViewModel = commentViewModel
        
        self.focusFigureViewModel = originalViewModel
        self.pageListViewModel = pageListViewModel
        self.searchViewModel = searchViewModel
        self.indexViewModel = indexViewModel
        
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
        // 기본 설정: 제스처 추가
        let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
        self.mainPDFView.addGestureRecognizer(pdfDrawingGestureRecognizer)
        pdfDrawingGestureRecognizer.drawingDelegate = viewModel.pdfDrawer
        viewModel.pdfDrawer.pdfView = self.mainPDFView
        viewModel.pdfDrawer.drawingTool = .none
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(postScreenTouch))
        gesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(gesture)
        
        let commentTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCommentTap(_:)))
        commentTapGesture.delegate = self
        self.view.addGestureRecognizer(commentTapGesture)
    }
    
    /// 데이터 Binding
    private func setBinding() {        
        self.pageListViewModel.$selectedDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let destination = destination else { return }
                guard let page = destination.page else { return }
                self?.mainPDFView.go(to: page)
            }
            .store(in: &self.cancellable)
        
// 지워야 함 🔥
//        self.searchViewModel.$searchDestination
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] destination in
//                guard let destination = destination,
//                      let page = destination.page else { return }
//                self?.mainPDFView.go(to: page)
//            }
//            .store(in: &self.cancellable)
        
        self.indexViewModel.$selectedDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let destination = destination,
                      let page = destination.page else { return }
                self?.mainPDFView.go(to: page)
            }
            .store(in: &self.cancellable)
        
        
        self.searchViewModel.$searchSelection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selection in
                self?.mainPDFView.setCurrentSelection(selection, animate: true)
            }
            .store(in: &self.cancellable)
        
        self.viewModel.$toolMode
            .sink { [weak self] mode in
                self?.mainPDFView.toolMode = mode
            }
            .store(in: &self.cancellable)
        
        self.viewModel.pdfDrawer.$drawingTool
            .sink { [weak self] drawingTool in
                self?.updateGestureRecognizer(mode: drawingTool)
            }
            .store(in: &cancellable)
        
        NotificationCenter.default.publisher(for: .PDFViewPageChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] noti in
                if let tempPDFView = noti.object as? PDFView, tempPDFView != self?.mainPDFView {
                    return
                }
                guard let page = self?.mainPDFView.currentPage else { return }
                guard let num = PDFSharedData.shared.document?.index(for: page) else { return }
                
                self?.pageLabelView.text = "\(num + 1) / \(PDFSharedData.shared.document!.pageCount)"
                
                self?.pageListViewModel.changedPageNumber = num
                self?.focusFigureViewModel.changedPageNumber = num
            }
            .store(in: &self.cancellable)
        
        
        // 하이라이트 기능 실행
        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
            .debounce(for: .milliseconds(700), scheduler: RunLoop.main)
        
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.viewModel.highlightText(in: self.mainPDFView, with: self.viewModel.selectedHighlightColor)
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
                        self.viewModel.translateViewPosition = screenPosition
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
    
    @objc
    func postScreenTouch() {
        NotificationCenter.default.post(name: .isCommentTapped, object: self, userInfo: ["hitted": false])
        NotificationCenter.default.post(name: .isPDFInfoMenuHidden, object: self, userInfo: ["hitted": false])
    }
    
    private func updateGestureRecognizer(mode: DrawingTool) {
        // 현재 설정된 제스처 인식기를 제거
        if let gestureRecognizers = self.mainPDFView.gestureRecognizers {
            for recognizer in gestureRecognizers {
                self.mainPDFView.removeGestureRecognizer(recognizer)
            }
        }
        
        // drawingToolMode에 따라 제스처 인식기를 추가
        if mode == .pencil || mode == .eraser || mode == .lasso {
            let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
            if mode == .lasso {
                pdfDrawingGestureRecognizer.allowedTouchTypes = [
                    NSNumber(value: UITouch.TouchType.indirect.rawValue),
                    NSNumber(value: UITouch.TouchType.direct.rawValue),
                    NSNumber(value: UITouch.TouchType.pencil.rawValue)
                ]
            } else if mode == .pencil || mode == .eraser {
                pdfDrawingGestureRecognizer.allowedTouchTypes = [
                    NSNumber(value: UITouch.TouchType.indirect.rawValue),
                    NSNumber(value: UITouch.TouchType.pencil.rawValue)
                ]
            } else {
                pdfDrawingGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
            }
            self.mainPDFView.addGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfDrawingGestureRecognizer.drawingDelegate = viewModel.pdfDrawer
            viewModel.pdfDrawer.pdfView = self.mainPDFView
        }
    }
    
    // 코멘트 버튼 annotation 제스처
    @objc
    func handleCommentTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: mainPDFView)
        
        guard let page = mainPDFView.page(for: location, nearest: true) else { return }
        let pageLocation = mainPDFView.convert(location, to: page)
        
        if let tappedAnnotation = page.annotation(at: pageLocation) {
            viewModel.isCommentTapped.toggle()
            
            if viewModel.isCommentTapped, let buttonID = tappedAnnotation.contents {
                    viewModel.selectedComments = commentViewModel.comments.filter { $0.buttonId.uuidString == buttonID }
                    commentViewModel.setCommentPosition(selectedComments: viewModel.selectedComments, pdfView: mainPDFView)
                viewModel.setHighlight(selectedComments: viewModel.selectedComments, isTapped: viewModel.isCommentTapped)
                }
            viewModel.setHighlight(selectedComments: viewModel.selectedComments, isTapped: viewModel.isCommentTapped)
        } else {
            print("No match comment annotation")
        }
    }
}

//canPerformAction()으로 menuAction 제한
class CustomPDFView: PDFView {
    var toolMode: ToolMode = .none
    var scrollView: UIScrollView? {
        self.subviews.first as? UIScrollView
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        switch toolMode {
        case .comment, .translate, .drawing:
            return false
            
        default:
            if action == #selector(copy(_:)) {
                return true
            }
            return false
        }
    }
}
