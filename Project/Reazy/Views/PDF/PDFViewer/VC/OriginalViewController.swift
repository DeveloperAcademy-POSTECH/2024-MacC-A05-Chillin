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
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUI()
        self.setData()
        self.setBinding()
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
                guard let selection = self.mainPDFView.currentSelection else { return }
                
                // 선택된 텍스트 가져오기
                let selectedText = selection.string ?? ""
                
//                // 현재 선택된 텍스트의 위치 가져오기
//                let selectionRect = selection.bounds(for: self.mainPDFView.currentPage!)
//
//                // PDF 뷰의 확대/축소 비율 가져오기
//                let scaleFactor = self.mainPDFView.scaleFactor
//
//                // 선택된 텍스트의 중심 위치 계산 (확대/축소 비율을 고려)
//                let bubblePosition = CGPoint(
//                    x: selectionRect.midX * scaleFactor,
//                    y: selectionRect.midY * scaleFactor - selectionRect.height / 2 * scaleFactor - 20 // 약간 위로 이동 (여백)
//                )
                
                DispatchQueue.main.async {
                    // ViewModel에 선택된 텍스트와 위치 업데이트
                    self.viewModel.selectedText = selectedText
                    // self.viewModel.bubbleViewPosition = bubblePosition // 위치 업데이트
                    
                    self.viewModel.bubbleViewVisible = !selectedText.isEmpty // 텍스트가 있을 때만 보여줌
                }
            }
            .store(in: &self.cancellable)
    }
}


#Preview {
    OriginalViewController(viewModel: .init())
}
