//
//  MainPDFViewController.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import UIKit
import PDFKit

/// 원문 모드 VC
final class OriginalViewController: UIViewController {

    let viewModel: OriginalViewModel = .shared
    
    let mainPDFView: PDFView = {
        let view = PDFView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray200
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.setUI()
        self.setData()
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
    }
}


#Preview {
    OriginalViewController()
}
