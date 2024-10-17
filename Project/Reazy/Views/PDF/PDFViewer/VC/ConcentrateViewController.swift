//
//  ContentrateViewController.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import UIKit
import PDFKit
import SwiftUI


final class ConcentrateViewController: UIViewController {
    
    let viewModel: OriginalViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setData()
        setUI()
    }
    
    lazy var pdfView: PDFView = {
        let view = PDFView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.pageShadowsEnabled = false
        view.pageBreakMargins = .init(top: 20, left: 0, bottom: 0, right: 0)
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
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.pdfView)
        NSLayoutConstraint.activate([
            self.pdfView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.pdfView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.pdfView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.pdfView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
    }
}



