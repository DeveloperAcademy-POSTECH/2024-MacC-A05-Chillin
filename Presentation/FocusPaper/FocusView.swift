//
//  FocusView.swift
//  Reazy
//
//  Created by 문인범 on 1/26/26.
//

import SwiftUI
import PDFKit


struct FocusView: UIViewControllerRepresentable {
    @Environment(FocusViewModel.self) private var focusViewModel
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    
    func makeUIViewController(context: Context) -> FocusPDFViewController {
        .init(
            mainPDFViewModel: mainPDFViewModel,
            focusViewModel: focusViewModel
        )
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}


class FocusPDFViewController: UIViewController {
    private let pdfView = PDFView()
    private let minimapView = FocusMinimapView()
    private let mainPDFViewModel: MainPDFViewModel
    private let focusViewModel: FocusViewModel
    private let indicator = UIActivityIndicatorView(style: .large)
    private var minimapHeightConstraint: NSLayoutConstraint?
    
    init(
        mainPDFViewModel: MainPDFViewModel,
        focusViewModel: FocusViewModel
    ) {
        self.mainPDFViewModel = mainPDFViewModel
        self.focusViewModel = focusViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPDF()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.mainPDFViewModel.mainPDFViewAction = .focusModeGuideAlert
        }
        super.viewWillAppear(animated)
    }
    
    
    deinit {
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.removeObserver(self, forKeyPath: "contentOffset")
        }
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            updateMinimap()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}



extension FocusPDFViewController {
    private func setupUI() {
        self.view.backgroundColor = .systemBackground
        
        // Setup PDFView
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        self.view.addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        minimapView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(minimapView)
        
        minimapHeightConstraint = minimapView.heightAnchor.constraint(equalToConstant: 200)
        
        NSLayoutConstraint.activate([
            minimapView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            minimapView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            minimapView.widthAnchor.constraint(equalToConstant: 174),
            minimapHeightConstraint!
        ])
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        self.view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
    private func setupPDF() {
        indicator.startAnimating()
        
        DispatchQueue.global().async { [weak self] in
            self?.focusViewModel.slicePDF()
            
            if let document = self?.focusViewModel.slicedDocument {
                DispatchQueue.main.async {
                    self?.indicator.stopAnimating()
                    self?.pdfView.document = document
                    self?.pdfView.minScaleFactor = 0.5
                    
                    self?.updateMinimap()
                }
            } else {
                DispatchQueue.main.async {
                    self?.indicator.stopAnimating()
                }
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange), name: .PDFViewPageChanged, object: pdfView)
        
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
        }
    }
    
    @objc private func handlePageChange() {
        updateMinimap()
    }
    
    @objc private func handleScroll() {
        updateMinimap()
    }
    
    private func updateMinimap() {
        guard let slicedPage = pdfView.currentPage,
              let pageIndex = pdfView.document?.index(for: slicedPage),
              let originalPage = PDFSharedData.shared.document?.page(at: pageIndex) else {
            return
        }
        
        let originalBounds = originalPage.bounds(for: .mediaBox)
        let aspectRatio = originalBounds.height / originalBounds.width
        let minimapWidth: CGFloat = 174 // Fixed width from constraints
        let newHeight = minimapWidth * aspectRatio
        
        if minimapHeightConstraint?.constant != newHeight {
            minimapHeightConstraint?.constant = newHeight
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        
        let visibleRect = pdfView.convert(pdfView.bounds, to: slicedPage)
        let slicedBounds = slicedPage.bounds(for: .mediaBox)
        
        let clampedVisibleRect = visibleRect.intersection(slicedBounds)
        
        if clampedVisibleRect.isNull || clampedVisibleRect.isEmpty {
            return
        }
        
        let totalHeight = slicedBounds.height
        let halfHeight = totalHeight / 2
        
        let midY = clampedVisibleRect.midY
        let isTopHalf = midY > halfHeight
        
        var normalizedX: CGFloat = 0
        var normalizedY: CGFloat = 0
        let normalizedW: CGFloat = 0.5
        var normalizedH: CGFloat = 0
        
        let targetHalfBounds: CGRect
        if isTopHalf {
            targetHalfBounds = CGRect(x: 0, y: halfHeight, width: slicedBounds.width, height: halfHeight)
            normalizedX = 0.0
        } else {
            targetHalfBounds = CGRect(x: 0, y: 0, width: slicedBounds.width, height: halfHeight)
            normalizedX = 0.5
        }
        
        let renderRect = clampedVisibleRect.intersection(targetHalfBounds)
        
        normalizedH = renderRect.height / halfHeight
        
        if isTopHalf {
            let relativeY = renderRect.midY - halfHeight
            let pdfY_0to1 = relativeY / halfHeight
            
            let centerY_UIKit = 1.0 - pdfY_0to1
            
            normalizedY = centerY_UIKit - (normalizedH / 2)
            
        } else {
            let relativeY = renderRect.midY
            let pdfY_0to1 = relativeY / halfHeight
            
            let centerY_UIKit = 1.0 - pdfY_0to1
            normalizedY = centerY_UIKit - (normalizedH / 2)
        }
        
        normalizedY = max(0, min(1.0 - normalizedH, normalizedY))
        
        let rect = CGRect(x: normalizedX, y: normalizedY, width: normalizedW, height: normalizedH)
        
        minimapView.update(page: originalPage, visibleRect: rect)
    }
}
