//
//  FocusView.swift
//  Reazy
//
//  Created by 문인범 on 1/26/26.
//

import SwiftUI



struct FocusView: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModel: MainPDFViewModel
    
    func makeUIViewController(context: Context) -> FocusPDFViewController {
        .init(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}



import PDFKit

class FocusPDFViewController: UIViewController {
    let pdfView = PDFView()
    let minimapView = PDFMinimapView()
    let viewModel: MainPDFViewModel
    
    
    init(viewModel: MainPDFViewModel) {
        self.viewModel = viewModel
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
        
        // Setup Minimap
        minimapView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(minimapView)
        
        // Aspect Ratio of Minimap should match the ORIGINAL A4ish page?
        // A4 is roughly 1:1.414.
        // Let's assume a reasonable size, e.g., width 100, height 140
        NSLayoutConstraint.activate([
            minimapView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            minimapView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            minimapView.widthAnchor.constraint(equalToConstant: 100),
            minimapView.heightAnchor.constraint(equalToConstant: 141) // Approx A4 ratio
        ])
    }
    
    private func setupPDF() {
        guard let document = PDFSharedData.shared.document else {
            print("fdsafsafasdfsadfdsfa")
            return
        }
        
        pdfView.document = document
        
        DispatchQueue.global().async {
            guard let slicedURL = PDFSlicer.slice(document: document) else {
                DispatchQueue.main.async {
//                    self.indicator.stopAnimating()
                    print("Failed to slice PDF")
                }
                return
            }
            
            if let document = PDFDocument(url: slicedURL) {
                DispatchQueue.main.async {
//                    self.indicator.stopAnimating()
                    self.pdfView.document = document
                    
                    // Trigger initial update
                    self.updateMinimap()
                }
            } else {
                DispatchQueue.main.async {
//                    self.indicator.stopAnimating()
                }
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange), name: .PDFViewPageChanged, object: pdfView)
        // NotificationCenter.default.addObserver(self, selector: #selector(handleScroll), name: .PDFViewVisibleDynamicBlock, object: pdfView)
        
        // PDFViewVisibleDynamicBlock is not a public Swift API.
        // We rely on KVO on scrollView.contentOffset for scroll updates.
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
        }
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
        
        // 좌표 매핑 로직 (Coordinate Mapping Logic)
        // 변환된 PDF 페이지 (Sliced): 높이 = 2H, 너비 = W/2
        // 원본 PDF 페이지 (Original): 높이 = H, 너비 = W
        
        // 변환된 페이지의 구조:
        // 위쪽 절반 (Top Half, 0 ~ H) -> 원본의 왼쪽 단 (Original Left Half)
        // 아래쪽 절반 (Bottom Half, H ~ 2H) -> 원본의 오른쪽 단 (Original Right Half)
        // (주의: PDF 좌표계는 일반적인 생각과 달리, 0이 바닥이고 위로 갈수록 커집니다.)
        
        // 변환된 페이지(Sliced Page) 좌표계에서의 현재 보이는 영역 찾기
        let visibleRect = pdfView.convert(pdfView.bounds, to: slicedPage)
        
        // 변환된 페이지의 전체 크기
        let slicedBounds = slicedPage.bounds(for: .mediaBox)
        let totalHeight = slicedBounds.height // 2H (원본 높이의 2배)
        
        // 현재 보이는 화면의 중심점(Y)을 기준으로, 우리가 어떤 '단'을 보고 있는지 판단
        let midY = visibleRect.midY
        
        // 참고: PDF 좌표계 기준 (0,0)은 좌측 하단입니다.
        // 따라서 y = 0 ~ H 구간은 '아래쪽 절반' (즉, 우리 로직상 오른쪽 단)입니다.
        // y = H ~ 2H 구간은 '위쪽 절반' (즉, 우리 로직상 왼쪽 단)입니다.
        
        // PDFSlicer 로직 다시 확인:
        // Top Half (Left): translateBy(0, halfHeight) -> y: H ~ 2H 위치에 그려짐
        // Bottom Half (Right): y: 0 ~ H 위치에 그려짐
        
        let halfHeight = totalHeight / 2 // 이것이 H (원본 페이지의 높이)
        
        var normalizedX: CGFloat = 0
        var normalizedY: CGFloat = 0
        var normalizedW: CGFloat = 0.5 // 너비는 항상 원본의 절반
        var normalizedH: CGFloat = 0   // 높이는 줌 상태에 따라 달라짐
        
        // 원본 페이지 높이 대비 뷰포트 높이 비율 계산
        // 만약 변환된 뷰(길쭉한 뷰)의 100%를 보고 있다면, 원본 전체 높이의 약 50%(한쪽 단 전체)를 보고 있는 셈입니다.
        let visibleHeightRatio = visibleRect.height / halfHeight
        normalizedH = visibleHeightRatio // 예: 0.2라면 해당 단 높이의 20%를 보고 있다는 뜻
        
        let isTopHalf = midY > halfHeight
        
        if isTopHalf {
            // 위쪽 절반을 보고 있음 == 원본의 왼쪽 단 (Left Column)
            normalizedX = 0.0 // 원본의 왼쪽
            
            // Y축 매핑:
            // Sliced Y 범위: H (위쪽 절반의 바닥) ~ 2H (위쪽 절반의 꼭대기)
            // 원본 페이지 내에서의 정규화된 Y (0~1, 바닥에서 위로):
            // (y - H) / H
            
            // 하지만 미니맵(UIKit)은 (0,0)이 좌측 상단(Top-Left)입니다.
            // 따라서 좌표를 뒤집어야 합니다. (1.0 - pdfY)
            
            // 현재 Sliced Y 예시:
            // 1.8H (꽤 위쪽) -> 원본의 0.8H 위치 -> UIKit(위에서 아래로) 기준으로는 0.2
            
            let pdfY = (midY - halfHeight) / halfHeight // 0~1 (바닥 -> 위)
            // UIKit 좌표계로 변환 (Top-Down)
            normalizedY = 1.0 - pdfY
            
            // 인디케이터 박스를 중앙에 맞추기 위한 보정
            normalizedY -= (normalizedH / 2)
            
        } else {
            // 아래쪽 절반을 보고 있음 == 원본의 오른쪽 단 (Right Column)
            normalizedX = 0.5 // 원본의 오른쪽
            
            // Y축 매핑:
            // Sliced Y 범위: 0 ~ H
            // (y) / H
            
            let pdfY = midY / halfHeight
            normalizedY = 1.0 - pdfY // UIKit 좌표계로 변환 (Top-Down)
            
            // 중앙 정렬 보정
            normalizedY -= (normalizedH / 2)
        }
        
        // 범위 벗어나지 않도록 클램핑 (0.0 ~ 1.0)
        normalizedY = max(0, min(1.0 - normalizedH, normalizedY))
        
        let rect = CGRect(x: normalizedX, y: normalizedY, width: normalizedW, height: normalizedH)
        
        minimapView.update(page: originalPage, visibleRect: rect)
    }
}


class PDFMinimapView: UIView {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        view.layer.borderWidth = 1.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.layer.borderWidth = 2.0
        return view
    }()
    
    private var currentPage: PDFPage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpUI() {
        self.backgroundColor = .white
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = .init(width: 0, height: 2)
        self.layer.shadowRadius = 4
        self.layer.cornerRadius = 8
        self.clipsToBounds = false // Show shadow
        
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        
        addSubview(imageView)
        // Indicator lives ON TOP of the image
        imageView.addSubview(indicatorView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    func update(page: PDFPage, visibleRect: CGRect) {
        // 썸네일 생성 (성능을 위해 캐싱 로직을 추가할 수 있음)
        if currentPage != page {
            currentPage = page
            let thumbnailSize = self.bounds.size
            
            // UI 끊김 방지를 위해 백그라운드 스레드에서 썸네일 생성
            DispatchQueue.global(qos: .userInteractive).async {
                let thumbnail = page.thumbnail(of: thumbnailSize, for: .mediaBox)
                DispatchQueue.main.async {
                    // 생성하는 동안 페이지가 바뀌지 않았는지 확인
                    if self.currentPage == page {
                        self.imageView.image = thumbnail
                    }
                }
            }
        }
        
        // 인디케이터 프레임 업데이트
        // visibleRect는 정규화된 좌표 (x: 0~1, y: 0~1)입니다.
        // PDF 좌표계는 좌하단이 (0,0)이지만, 여기로 넘어오는 visibleRect는
        // SlicedPDFViewController에서 이미 UIKit 좌표계(좌상단 0,0)로 변환되어 넘어옵니다.
        
        let viewWidth = self.bounds.width
        let viewHeight = self.bounds.height
        
        let indicatorX = visibleRect.origin.x * viewWidth
        let indicatorY = visibleRect.origin.y * viewHeight // UIKit 기준 (상단이 0)
        let indicatorW = visibleRect.width * viewWidth
        let indicatorH = visibleRect.height * viewHeight
        
        UIView.animate(withDuration: 0.1) {
            self.indicatorView.frame = CGRect(x: indicatorX, y: indicatorY, width: indicatorW, height: indicatorH)
        }
    }
}



class PDFSlicer {
    
    /// 원본 PDF를 받아서 각 페이지를 좌/우로 분할한 새로운 PDF 파일을 생성합니다.
    /// - Parameter sourceURL: 원본 PDF 파일의 URL
    /// - Returns: 생성된 임시 PDF 파일의 URL (실패 시 nil)
    static func slice(document: PDFDocument) -> URL? {
//        guard let document = PDFDocument(url: pdfUrl) else { return nil }
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let outputURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        
        // PDF 렌더러 생성 (메타데이터 없이 일단 진행)
        // 전체 페이지 사이즈를 미리 알 수 없으므로, 페이지마다 컨텍스트를 새로 시작하는 방식 사용
        
        guard let context = CGContext(outputURL as CFURL, mediaBox: nil, nil) else {
            print("Failed to create PDF context")
            return nil
        }
        
        // 각 페이지 순회
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            
            // 원본 페이지의 MediaBox (전체 크기)
            let mediaBox = page.bounds(for: .mediaBox)
            

            // 반으로 나눌 크기 계산 (너비는 절반, 높이는 그대로)
            let halfWidth = mediaBox.width / 2
            let halfHeight = mediaBox.height
            
            // 새로운 페이지 크기: 너비는 절반, 높이는 2배 (위아래로 붙임)
            var newMediaBox = CGRect(x: 0, y: 0, width: halfWidth, height: halfHeight * 2)
            let pageInfo = [ kCGPDFContextMediaBox: Data(bytes: &newMediaBox, count: MemoryLayout<CGRect>.size) as CFData ] as CFDictionary
            
            // 한 페이지 시작 (Top: Left, Bottom: Right)
            context.beginPDFPage(pageInfo)
            
            // --- 1. Top Half (원본의 왼쪽 영역) ---
            context.saveGState()
            
            // 좌표계 변환:
            // 새 페이지의 상단 절반(y: halfHeight ~ 2*halfHeight)에 그려야 합니다.
            // PDF 좌표계는 (0,0)이 하단입니다.
            // 따라서 y축으로 halfHeight 만큼 전체를 들어 올려서 그리면,
            // 원본이 위쪽 절반 위치에 나타나게 됩니다.
            context.translateBy(x: 0, y: halfHeight)
            
            // 그리기 (원본의 (0,0)이 현재 컨텍스트의 (0, halfHeight)에 매핑되어 그려짐)
            page.draw(with: .mediaBox, to: context)
            
            context.restoreGState()
            
            
            // --- 2. Bottom Half (원본의 오른쪽 영역) ---
            context.saveGState()
            
            // 좌표계 변환:
            // 새 페이지의 하단 절반(y: 0 ~ halfHeight)에 그려야 합니다.
            // 원본의 오른쪽 부분(x: halfWidth ~ Width)을 가져와서 (0,0) 위치부터 시작하도록 해야 합니다.
            // 따라서 전체를 왼쪽으로 halfWidth 만큼 당깁니다 (-halfWidth).
            // y축 이동은 필요 없습니다 (이미 하단이 0이므로).
            context.translateBy(x: -halfWidth, y: 0)
            
            // 그리기
            page.draw(with: .mediaBox, to: context)
            
            context.restoreGState()
            
            context.endPDFPage()
        }
        
        context.closePDF()
        
        return outputURL
    }
}
