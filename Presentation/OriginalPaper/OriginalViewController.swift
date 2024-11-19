//
//  MainPDFViewController.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import SwiftUI
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
    var selectionWorkItem: DispatchWorkItem?
    
    
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
            // TODO: - Core data에서 배열 load 하는 곳
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
        
        self.searchViewModel.$searchDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let destination = destination,
                      let page = destination.page else { return }
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
        
        self.viewModel.$drawingToolMode
            .sink { [weak self] mode in
                // ViewModel toolMode의 변경 감지해서 pencil이랑 eraser일 때만 펜슬 제스처 인식하게
                self?.updateGestureRecognizer(for: mode)
                // toolMode 변경에 따라 canPerformAction 동작하도록
                self?.mainPDFView.drawingToolMode = mode
            }
            .store(in: &cancellable)
        
        NotificationCenter.default.publisher(for: .PDFViewPageChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let page = self?.mainPDFView.currentPage else { return }
                guard let num = PDFSharedData.shared.document?.index(for: page) else { return }
                self?.pageListViewModel.changedPageNumber = num
                self?.focusFigureViewModel.changedPageNumber = num
            }
            .store(in: &self.cancellable)
        
        // 현재 드래그된 텍스트 가져오는 함수
        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
            .debounce(for: .milliseconds(700), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                switch self.viewModel.toolMode {
                case .drawing:
                    switch self.viewModel.drawingToolMode {
                    case .highlight:
                        DispatchQueue.main.async {
                            self.viewModel.highlightText(in: self.mainPDFView, with: self.viewModel.selectedHighlightColor)              // 하이라이트 기능
                        }
                    default:
                        return
                    }
                    
                case .translate, .comment:
                    guard let selection = self.mainPDFView.currentSelection else {
                        // 선택된 텍스트가 없을 때 특정 액션
                        self.viewModel.selectedText = ""                                // 선택된 텍스트 초기화
                        self.viewModel.isTranslateViewVisible = true                        // 말풍선 뷰 숨김
                        return
                    }
                    
                    guard let text = selection.string else { return }
                    
                    self.selectionWorkItem?.cancel()
                    
                    let workItem = DispatchWorkItem { [weak self] in
                        guard let self = self else { return }
                        if let page = selection.pages.first {
                            
                            // PDFSelection의 bounds 추출(CGRect)
                            let bound = selection.bounds(for: page)
                            let convertedBounds = self.mainPDFView.convert(bound, from: page)
                            
                            //comment position 설정
                            let commentPosition = CGPoint(
                                x: convertedBounds.midX,
                                y: convertedBounds.maxY + 50
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
                                self.viewModel.translateViewPosition = screenPosition              // 위치 업데이트
                                self.viewModel.isTranslateViewVisible = !selectedText.isEmpty        // 텍스트가 있을 때만 보여줌
                                
                                self.viewModel.commentSelection = selection
                                self.viewModel.commentInputPosition = commentPosition
                                self.commentViewModel.selectedBounds = bound
                            }
                        }
                    }
                    
                    // 텍스트 선택 후 딜레이
                    self.selectionWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
                    
                default:
                    return
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
        NotificationCenter.default.post(name: .isSearchViewHidden, object: self, userInfo: ["hitted": true])
        NotificationCenter.default.post(name: .isCommentTapped, object: self, userInfo: ["hitted": false])
        NotificationCenter.default.post(name: .isPDFInfoMenuHidden, object: self, userInfo: ["hitted": false])
    }
    
    private func updateGestureRecognizer(for mode: DrawingToolMode) {
        // 현재 설정된 제스처 인식기를 제거
        if let gestureRecognizers = self.mainPDFView.gestureRecognizers {
            for recognizer in gestureRecognizers {
                self.mainPDFView.removeGestureRecognizer(recognizer)
            }
        }
        
        // drawingToolMode에 따라 제스처 인식기를 추가
        if mode == .pencil || mode == .eraser {
            let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
            self.mainPDFView.addGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfDrawingGestureRecognizer.drawingDelegate = viewModel.pdfDrawer
            viewModel.pdfDrawer.pdfView = self.mainPDFView
            viewModel.pdfDrawer.drawingTool = .none
        }
    }
    
    // 코멘트 버튼 annotation 제스처
    @objc
    func handleCommentTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: mainPDFView)
        
        guard let page = mainPDFView.page(for: location, nearest: true) else { return }
        let pageLocation = mainPDFView.convert(location, to: page)
        
        /// 해당 위치에 Annotation이 있는지 확인
        if let tappedAnnotation = page.annotation(at: pageLocation) {
            if let buttonID = tappedAnnotation.contents {
                viewModel.selectedComments = commentViewModel.comments.filter { $0.buttonId.uuidString == buttonID }
                viewModel.isCommentTapped.toggle()
                if viewModel.isCommentTapped {
                    commentViewModel.setCommentPosition(selectedComments: viewModel.selectedComments, pdfView: mainPDFView)
                    viewModel.setHighlight(selectedComments: viewModel.selectedComments, isTapped: viewModel.isCommentTapped)
                } else {
                    viewModel.setHighlight(selectedComments: viewModel.selectedComments, isTapped: viewModel.isCommentTapped)
                }
            } else {
                print("No match comment annotation")
            }
        }
    }
}

//canPerformAction()으로 menuAction 제한
class CustomPDFView: PDFView {
    var toolMode: ToolMode = .none
    var drawingToolMode: DrawingToolMode = .none
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch toolMode {
        case .comment, .translate:
            return false
            
        case .drawing:
            switch drawingToolMode {
            case .highlight:
                return false
            default:
                if action == #selector(copy(_:)) {
                    return true
                }
                return false
            }
            
        default:
            if action == #selector(copy(_:)) {
                return true
            }
            return false
        }
    }
}