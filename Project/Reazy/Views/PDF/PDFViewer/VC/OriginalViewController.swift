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
        view.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.autoScales = true
        return view
    }()
    
    // for drawing
    var shouldUpdatePDFScrollPosition = true
    let pdfDrawer = PDFDrawer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUI()
        self.setData()
        self.setBinding()
        
        print("여기까진 왔다!")
        
        let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
        self.mainPDFView.addGestureRecognizer(pdfDrawingGestureRecognizer)
        print("여기까진 왔다!2")
        pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
        pdfDrawer.pdfView = self.mainPDFView
        pdfDrawer.drawingTool = .pencil
        print("여기까진 왔다!3")
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
    }
    
    /// 데이터 Binding
    private func setBinding() {
        self.viewModel.$selectedDestination
            .sink { [weak self] destination in
                guard let page = destination?.page else { return }
                self?.mainPDFView.go(to: page)
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
                guard let selection = self.mainPDFView.currentSelection else {
                    // 선택된 텍스트가 없을 때 특정 액션
                    self.viewModel.selectedText = "" // 선택된 텍스트 초기화
                    self.viewModel.bubbleViewVisible = false // 말풍선 뷰 숨김
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
                    self.viewModel.bubbleViewPosition = screenPosition // 위치 업데이트
                    
                    self.viewModel.bubbleViewVisible = !selectedText.isEmpty // 텍스트가 있을 때만 보여줌
                }
            }
            .store(in: &self.cancellable)

    }
}


#Preview {
    OriginalViewController(viewModel: .init())
}
