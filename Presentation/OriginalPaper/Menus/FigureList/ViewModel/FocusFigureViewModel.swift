//
//  OriginalPaperViewModel.swift
//  Reazy
//
//  Created by 문인범 on 11/15/24.
//

import Foundation
import Network
import PDFKit
import Combine


@MainActor
class FocusFigureViewModel: ObservableObject {
    @Published public var focusPages: [FocusAnnotation] = []
    @Published public var figures: [FigureAnnotation] = []
    @Published public var figureStatus: FigureStatus = .networkDisconnection
    @Published public var changedPageNumber: Int?
    

    let a = NotificationCenter.default.publisher(for: .isPDFCaptured)
    
    var cancellables: Set<AnyCancellable> = []
    private var focusFigureUseCase: FocusFigureUseCase
    
    init(focusFigureUseCase: FocusFigureUseCase) {
        self.focusFigureUseCase = focusFigureUseCase
        self.isPDFCaptured()
    }
}


extension FocusFigureViewModel {
    public func fetchAnnotations() {
        
        var paperInfo = self.focusFigureUseCase.pdfSharedData.paperInfo
        let document = self.focusFigureUseCase.pdfSharedData.document
        
        if let isFigureSaved = paperInfo?.isFigureSaved ,
           !isFigureSaved {
            downloadFocusFigure()
            paperInfo?.isFigureSaved = true
            return
        }
        
        switch self.focusFigureUseCase.loadFigures() {
        case .success(let figureList):
            
            let height = document!.page(at: 0)!.bounds(for: .mediaBox).height
            let result = figureList.map { $0.toEntity(pageHeight: height) }
            
            if result.isEmpty {
                self.figureStatus = .empty
                return
            }
            
            DispatchQueue.main.async {
                self.figures = result
                self.figureStatus = .complete
            }
            
        case .failure:
            self.figureStatus = .empty
        }
    }
    
    public var getDocument: PDFDocument? {
        self.focusFigureUseCase.pdfSharedData.document
    }
    
    
    private func downloadFocusFigure() {
        NWPathMonitor().startMonitoring { isConnected in
            if !isConnected {
                DispatchQueue.main.async {
                    self.figureStatus = .networkDisconnection
                }
                return
            }
            
            DispatchQueue.main.async {
                self.figureStatus = .loading
            }
            
            var isStale = false
            
            guard let url = try? URL.init(
                resolvingBookmarkData: self.focusFigureUseCase.pdfSharedData.paperInfo!.url,
                bookmarkDataIsStale: &isStale),
                  url.startAccessingSecurityScopedResource() else {
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            Task.init {
                let height = self.focusFigureUseCase.getPDFHeight()
                var paperInfo = self.focusFigureUseCase.pdfSharedData.paperInfo!
                
                await self.focusFigureUseCase.excute(process: .processFulltextDocument, url: url) {
                    switch $0 {
                    case .success(let layout):
                        DispatchQueue.main.async {
                            self.figures = layout.toFigureEntities(pageHeight: height)
                            self.focusPages = layout.toFocusEntities(pageHeight: height)
                            self.figureStatus = .complete
                            
                            self.saveFigures(figures: layout.toCoreData())
                            
                            paperInfo.isFigureSaved = true
                            self.focusFigureUseCase.editPaperInfo(info: paperInfo)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.figureStatus = .empty
                            print(error)
                        }
                    }
                }
            }
        }
    }
    
    
    public func setFigureDocument(for index: Int) -> PDFDocument? {
        
        guard index >= 0 && index < self.figures.count else {           // 인덱스가 유효한지 확인
            print("Invalid index")
            return nil
        }
        
        DispatchQueue.main.async {
            self.figures.sort { $0.page < $1.page }                     // figure와 table 페이지 순서 정렬
        }
        
        let document = PDFDocument()                                    // 새 PDFDocument 생성
        let annotation = self.figures[index]                            // 주어진 인덱스의 annotation 가져오기
        
        // 해당 페이지 가져오기
        guard let page = self.focusFigureUseCase.pdfSharedData.document?.page(at: annotation.page - 1)?.copy()
                as? PDFPage else {
            print("Failed to get page")
            return nil
        }
        
        page.displaysAnnotations = false
        
        
        let original = page.bounds(for: .mediaBox)                      // 원본 페이지의 bounds 가져오기
        let croppedRect = original.intersection(annotation.position)    // 크롭 영역 계산 (교차 영역)
        
        page.setBounds(croppedRect, for: .mediaBox)                     // 페이지의 bounds 설정
        document.insert(page, at: 0)                                    // 새 document에 페이지 추가
        
        return document                                                 // 생성된 PDFDocument 변환
    }
    
    
    private func saveFigures(figures: [Figure]) {
        figures.forEach { self.focusFigureUseCase.saveFigures(with: $0) }
    }
    
    
    enum FigureStatus {
        case networkDisconnection
        case loading
        case empty
        case complete
    }
}




extension FocusFigureViewModel {
    public func setFocusDocument() -> PDFDocument {
        
        let document = PDFDocument()
        
        var pageIndex = 0
        
        self.focusPages.forEach { annotation in
            guard let page = self.focusFigureUseCase.pdfSharedData.document?
                .page(at: annotation.page - 1)?.copy() as? PDFPage else {
                return
            }
            page.displaysAnnotations = false
            
            let original = page.bounds(for: .mediaBox)
            let croppedRect = original.intersection(annotation.position)
            
            page.setBounds(croppedRect, for: .mediaBox)
            document.insert(page, at: pageIndex)
            pageIndex += 1
        }
        
        // TODO: 밑 주석 추후에 수정 예정
        /*
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "test.pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: .zero)
        try! renderer.writePDF(to: url) { context in
            let pdfContext = context.cgContext
            
            self.focusPages.forEach { annotation in
                guard let page = self.focusFigureUseCase.pdfSharedData.document?
                    .page(at: annotation.page - 1)?.copy() as? PDFPage else {
                    return
                }
                page.displaysAnnotations = false
                
                guard let pdfRef = page.pageRef else { return }
                
                var mediaBox = pdfRef.getBoxRect(.mediaBox)
                pdfContext.beginPage(mediaBox: &mediaBox)
                pdfContext.drawPDFPage(pdfRef)
            }
            
            pdfContext.endPage()
        }
        
        let resultDocument = PDFDocument(url: url)!
         */
        
        return document
    }
    
    func isPDFCaptured() {
        self.a
            .sink { [weak self] in
                guard let figure = $0.object as? Figure else { return }
                guard let height = self?.focusFigureUseCase.getPDFHeight() else { return }
                self?.focusFigureUseCase.saveFigures(with: figure)
                self?.figures.append(figure.toEntity(pageHeight: height))
            }
            .store(in: &self.cancellables)
    }
}
