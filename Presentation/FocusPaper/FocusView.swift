//
//  FocusView.swift
//  Reazy
//
//  Created by 문인범 on 1/26/26.
//

import SwiftUI
import PDFKit
import Combine


struct FocusView: UIViewControllerRepresentable {
    @Environment(FocusViewModel.self) private var focusViewModel
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject private var pageListViewModel: PageListViewModel
    @EnvironmentObject private var indexViewModel: IndexViewModel
    
    func makeUIViewController(context: Context) -> FocusPDFViewController {
        .init(
            mainPDFViewModel: mainPDFViewModel,
            focusViewModel: focusViewModel,
            pageListViewModel: pageListViewModel,
            indexViewModel: indexViewModel
        )
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}


class FocusPDFViewController: UIViewController {
    private let pdfView = PDFView()
    private let minimapView = FocusMinimapView()
    private let mainPDFViewModel: MainPDFViewModel
    private let focusViewModel: FocusViewModel
    private let pageListViewModel: PageListViewModel
    private let indexViewModel: IndexViewModel
    private let indicator = UIActivityIndicatorView(style: .large)
    private var minimapHeightConstraint: NSLayoutConstraint?
    private var cancellables: Set<AnyCancellable> = []
    
    private let labelBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray300
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.primary3.cgColor
        view.alpha = 0
        return view
    }()
    private let pageLabelView: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "1 / \(PDFSharedData.shared.document!.pageCount)"
        view.font = UIFont(name: ReazyFontType.pretendardMediumFont, size: 16)
        view.textColor = .gray700
        view.alpha = 0
        return view
    }()
    private var pageLabelTimer: Timer?
    
    init(
        mainPDFViewModel: MainPDFViewModel,
        focusViewModel: FocusViewModel,
        pageListViewModel: PageListViewModel,
        indexViewModel: IndexViewModel
    ) {
        self.mainPDFViewModel = mainPDFViewModel
        self.focusViewModel = focusViewModel
        self.pageListViewModel = pageListViewModel
        self.indexViewModel = indexViewModel
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
        let isFocusGuideViewDoNotShowAgain = UserDefaults.standard.focusGuideViewDoNotShowAgain
        
        if !isFocusGuideViewDoNotShowAgain {
            DispatchQueue.main.async { [weak self] in
                self?.mainPDFViewModel.mainPDFViewAction = .focusModeGuideAlert
            }
        }
        
        if mainPDFViewModel.statusStack.isSearchSelected {
            DispatchQueue.main.async { [weak self] in
                self?.mainPDFViewModel.statusStack.searchToggle()
            }
        }
        if mainPDFViewModel.statusStack.isCollectionSelected {
            DispatchQueue.main.async { [weak self] in
                self?.mainPDFViewModel.statusStack.collectionToggle()
            }
        }
        
        self.updateScaleFactor()
        self.updatePageIndex()
        
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
        
        self.pdfView.addSubview(self.labelBackgroundView)
        NSLayoutConstraint.activate([
            self.labelBackgroundView.topAnchor.constraint(equalTo: self.pdfView.topAnchor, constant: 28),
            self.labelBackgroundView.trailingAnchor.constraint(equalTo: self.pdfView.trailingAnchor, constant: -28),
            self.labelBackgroundView.widthAnchor.constraint(equalToConstant: 72),
            self.labelBackgroundView.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        self.labelBackgroundView.addSubview(self.pageLabelView)
        NSLayoutConstraint.activate([
            self.pageLabelView.centerXAnchor.constraint(equalTo: self.labelBackgroundView.centerXAnchor),
            self.pageLabelView.centerYAnchor.constraint(equalTo: self.labelBackgroundView.centerYAnchor)
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
                    self?.updateScaleFactor()
                    self?.updatePageIndex()
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
        
        NotificationCenter.default.publisher(for: .PDFViewScaleChanged, object: self.pdfView)
            .sink { [weak self] _ in
                self?.mainPDFViewModel.pdfOriginalViewScaleFactor = self?.pdfView.scaleFactor
            }
            .store(in: &self.cancellables)
        
        
        NotificationCenter.default.publisher(for: .PDFViewPageChanged, object: self.pdfView)
            .sink { [weak self] _ in
                let page = self?.pdfView.currentPage
                let pageIndex = self?.focusViewModel.getPageIndex(page: page)
                
                self?.mainPDFViewModel.pdfOriginalViewPageIndex = pageIndex
                
                if let page = page, let document = self?.focusViewModel.slicedDocument {
                    let num = document.index(for: page)
                    
                    if (num &+ 1) < 0 { return }
                    
                    // 오버플로우 순환 연산
                    self?.pageLabelView.text = "\(num + 1) / \(document.pageCount)"
                }
            }
            .store(in: &self.cancellables)
        
        NotificationCenter.default.publisher(for: .didSelectAnnotationCollection)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] noti in
                guard let index = noti.userInfo?["index"] as? Int,
                      let slicedPage = self?.focusViewModel.slicedDocument?.page(at: index) else { return }
                
                self?.pdfView.go(to: slicedPage)
            }
            .store(in: &self.cancellables)
        
        if let scrollView = self.pdfView.subviews.first as? UIScrollView {
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
                .store(in: &self.cancellables)
        }
        
        self.pageListViewModel.$selectedDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let destination = destination,
                      let originalPage = destination.page else { return }
                
                let pageIndex = PDFSharedData.shared.document?.index(for: originalPage) ?? -1
                if pageIndex < 0 { return }
                
                if let slicedPage = self?.focusViewModel.slicedDocument?.page(at: pageIndex) {
                    self?.pdfView.go(to: slicedPage)
                }
            }
            .store(in: &self.cancellables)
            
        self.indexViewModel.$selectedDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let destination = destination,
                      let originalPage = destination.page else { return }
                
                let pageIndex = PDFSharedData.shared.document?.index(for: originalPage) ?? -1
                if pageIndex < 0 { return }
                
                if let slicedPage = self?.focusViewModel.slicedDocument?.page(at: pageIndex) {
                    self?.pdfView.go(to: slicedPage)
                }
            }
            .store(in: &self.cancellables)
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
    
    private func updateScaleFactor() {
        if let scaleFactor = mainPDFViewModel.pdfFocusViewScaleFactor {
            DispatchQueue.main.async {
                self.pdfView.scaleFactor = scaleFactor
            }
        }
    }
    
    private func updatePageIndex() {
        if let pageIndex = mainPDFViewModel.pdfFocusViewPageIndex {
            DispatchQueue.main.async {
                if let page = self.focusViewModel.slicedDocument?.page(at: pageIndex) {
                    self.pdfView.go(to: page)
                }
            }
        }
    }
}
