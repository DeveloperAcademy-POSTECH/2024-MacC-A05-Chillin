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
    
    let viewModel: OriginalViewModel
    
    var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setData()
        setUI()
        setBinding()
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
    
    
    
    init(viewModel: OriginalViewModel) {
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
        let width = UIScreen.main.bounds.width
        
        let backView = UIView()
        backView.translatesAutoresizingMaskIntoConstraints = false
        backView.backgroundColor = .white
        
        self.view.addSubview(backView)
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: self.view.topAnchor),
            backView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            backView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            backView.widthAnchor.constraint(equalToConstant: width / 1.8)
        ])
        
        // TODO: 집중모드에서 백그라운드 컬러에 따른 확대,축소 기능 넣을지 여부 확인
        self.view.backgroundColor = .gray200
        
        self.view.addSubview(self.pdfView)
        NSLayoutConstraint.activate([
            self.pdfView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.pdfView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
//            self.pdfView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//            self.pdfView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.pdfView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.pdfView.widthAnchor.constraint(equalToConstant: width / 2)
        ])
        
        // pdf view의 초기 scale 설정
        self.pdfView.scaleFactor = 2.5
    }
    
    /// 데이터 바인딩
    private func setBinding() {
        self.viewModel.$selectedDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let page = self?.viewModel.findFocusPageNum(destination: destination) else {
                    print("here?")
                    return
                }
                
                print(page)
                
                self?.pdfView.go(to: page)
            }
            .store(in: &cancellables)
    }
}



