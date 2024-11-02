//
//  ContentrateViewController.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import UIKit
import PDFKit
import Combine

final class ConcentrateViewController: UIViewController {
    
    let viewModel: MainPDFViewModel
    
    var cancellables: Set<AnyCancellable> = []
    
    var isPageDestinationWorking: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setData()
        setUI()
        setBinding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let focusPageNum = self.viewModel.focusAnnotations.firstIndex { $0.page == self.viewModel.changedPageNumber + 1}
        
        guard let page = self.viewModel.focusDocument?.page(at: focusPageNum ?? 0) else { return }
        
        self.pdfView.go(to: page)
    }
    
    lazy var pdfView: PDFView = {
        let view = PDFView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.pageShadowsEnabled = false
        view.pageBreakMargins = .init(top: 20, left: 0, bottom: 0, right: 0)
        view.autoScales = false
        view.subviews.first!.backgroundColor = .white
        return view
    }()
    
    
    
    init(viewModel: MainPDFViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 초기 세팅
extension ConcentrateViewController {
    /// filter 된 document 불러오기
    private func setData() {
        if self.viewModel.focusAnnotations.isEmpty {
            print("empty!!")
            return
        }
        
        self.viewModel.setFocusDocument()
        self.pdfView.document = self.viewModel.focusDocument
    }
    
    /// UI 설정
    private func setUI() {
        self.view.addSubview(self.pdfView)
        NSLayoutConstraint.activate([
            self.pdfView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.pdfView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.pdfView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.pdfView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        // pdf view의 초기 scale 설정
        self.pdfView.scaleFactor = 2
    }
    
    /// 데이터 바인딩
    private func setBinding() {
        self.viewModel.$selectedDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                self?.isPageDestinationWorking = true
                
                guard let page = self?.viewModel.findFocusPageNum(destination: destination) else {
                    self?.isPageDestinationWorking = false
                    return
                }
                
                self?.pdfView.go(to: page)
                self?.isPageDestinationWorking = false
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .PDFViewPageChanged)
            .sink { [weak self] _ in
                if let flag = self?.isPageDestinationWorking, flag { return }
                
                // SplitView에서 발생하는 비동기 작업으로 인한 지연 실행 및 예외 처리 추가
                if let currentPage = self?.pdfView.currentPage,
                   let currentPageNum = self?.viewModel.focusDocument?.index(for: currentPage),
                   currentPageNum < self?.viewModel.focusAnnotations.count ?? 0 {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let pageNum = self?.viewModel.focusAnnotations[currentPageNum]
                        
                        defer {
                            DispatchQueue.main.async {
                                self?.viewModel.changedPageNumber = pageNum?.page ?? 0
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.viewModel.changedPageNumber = pageNum?.page ?? 0
                        }
                    }
                    
                } else {
                    print("Warning: currentPageNum is out of focusAnnotations range")
                }
            }
            .store(in: &self.cancellables)
    }
}
