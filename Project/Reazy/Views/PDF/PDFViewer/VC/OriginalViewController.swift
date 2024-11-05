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
final class OriginalViewController:
    UIViewController {
    
    let viewModel: MainPDFViewModel
    
    var cancellable: Set<AnyCancellable> = []
    
    let mainPDFView: PDFView = {
        let view = PDFView()
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
        self.setBinding()
        
        // 기본 설정: 제스처 추가
        let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
        self.mainPDFView.addGestureRecognizer(pdfDrawingGestureRecognizer)
        pdfDrawingGestureRecognizer.drawingDelegate = viewModel.pdfDrawer
        viewModel.pdfDrawer.pdfView = self.mainPDFView
        viewModel.pdfDrawer.drawingTool = .none

        let gesture = UITapGestureRecognizer(target: self, action: #selector(postScreenTouch))
        gesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(gesture)

        // ViewModel toolMode의 변경 감지해서 pencil이랑 eraser일 때만 펜슬 제스처 인식하게
        viewModel.$toolMode
            .sink { [weak self] mode in
                self?.updateGestureRecognizer(for: mode)
            }
            .store(in: &cancellable)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.goToPage(at: viewModel.changedPageNumber)
    }
    
    init(viewModel: MainPDFViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func postScreenTouch() {
        NotificationCenter.default.post(name: .isSearchViewHidden, object: self, userInfo: ["hitted": true])
    }

    private func updateGestureRecognizer(for mode: ToolMode) {
        // 현재 설정된 제스처 인식기를 제거
        if let gestureRecognizers = self.mainPDFView.gestureRecognizers {
            for recognizer in gestureRecognizers {
                self.mainPDFView.removeGestureRecognizer(recognizer)
            }
        }

        // toolMode에 따라 제스처 인식기를 추가
        if mode == .pencil || mode == .eraser {
            let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
            self.mainPDFView.addGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfDrawingGestureRecognizer.drawingDelegate = viewModel.pdfDrawer
            viewModel.pdfDrawer.pdfView = self.mainPDFView
            viewModel.pdfDrawer.drawingTool = .none
        }
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
        self.viewModel.setPDFDocument(url: Bundle.main.url(forResource: "engPD5", withExtension: "pdf")!)
        self.mainPDFView.document = self.viewModel.document
        
        // 집중모드 데이터 패치
        self.viewModel.fetchFocusAnnotations()
        
        // 썸네일 이미지 패치
        self.viewModel.fetchThumbnailImage()
        
        // PDF 문서 로드 완료 후 드로잉 데이터 패치
        DispatchQueue.main.async {
            self.viewModel.pdfDrawer.pdfView = self.mainPDFView
            self.viewModel.pdfDrawer.loadDrawings()
            // TODO: - Core data load 하는 곳
        }
    }
    
    /// 데이터 Binding
    private func setBinding() {
        self.viewModel.$selectedDestination
            .sink { [weak self] destination in
                guard let destination = destination else { return }
                guard let page = destination.page else { return }
                self?.mainPDFView.go(to: page)
            }
            .store(in: &self.cancellable)
        
        self.viewModel.$searchSelection
            .sink { [weak self] selection in
                self?.mainPDFView.setCurrentSelection(selection, animate: true)
            }
            .store(in: &self.cancellable)
        
        NotificationCenter.default.publisher(for: .PDFViewPageChanged)
            .sink { [weak self] _ in
                guard let page = self?.mainPDFView.currentPage else { return }
                guard let num = self?.viewModel.document?.index(for: page) else { return }
                DispatchQueue.main.async {
                    self?.viewModel.changedPageNumber = num
                }
            }
            .store(in: &self.cancellable)
        
        // 현재 드래그된 텍스트 가져오는 함수
        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                switch self.viewModel.toolMode {
                case .highlight:
                    DispatchQueue.main.async {
                        self.viewModel.highlightText(in: self.mainPDFView, with: self.viewModel.selectedHighlightColor)              // 하이라이트 기능
                    }
                case .translate:
                    guard let selection = self.mainPDFView.currentSelection else {
                        // 선택된 텍스트가 없을 때 특정 액션
                        self.viewModel.selectedText = ""                                // 선택된 텍스트 초기화
                        self.viewModel.bubbleViewVisible = false                        // 말풍선 뷰 숨김
                        return
                    }
                    
                    guard let page = selection.pages.first else {
                        return
                    }
                    
                    // PDFSelection의 bounds 추출(CGRect)
                    let bound = selection.bounds(for: page)
                    
                    // 선택된 텍스트 가져오기
                    let selectedText = selection.string ?? ""
                    
                    // PDFPage의 좌표를 PDFView의 좌표로 변환
                    let pagePosition = self.mainPDFView.convert(bound, from: page)
                    
                    // PDFView의 좌표를 Screen의 좌표로 변환
                    let screenPosition = self.mainPDFView.convert(pagePosition, to: nil)
                    
                    DispatchQueue.main.async {
                        // ViewModel에 선택된 텍스트와 위치 업데이트
                        self.viewModel.selectedText = selectedText
                        self.viewModel.bubbleViewPosition = screenPosition              // 위치 업데이트
                        self.viewModel.bubbleViewVisible = !selectedText.isEmpty        // 텍스트가 있을 때만 보여줌
                    }
                default:
                    return
                }
            }
            .store(in: &self.cancellable)
    }
}


#Preview {
    OriginalViewController(viewModel: .init())
}
