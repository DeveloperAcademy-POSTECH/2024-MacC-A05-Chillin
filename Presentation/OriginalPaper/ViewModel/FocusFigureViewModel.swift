//
//  OriginalPaperViewModel.swift
//  Reazy
//
//  Created by 문인범 on 11/15/24.
//

import Foundation
import Network
import PDFKit


@MainActor
class FocusFigureViewModel: ObservableObject {
    @Published public var figures: [FigureAnnotation] = []
    @Published public var figureStatus: FigureStatus = .networkDisconnection
    
    
    private var focusFigureUseCase: FocusFigureUseCase
    
    init(focusFigureUseCase: FocusFigureUseCase) {
        self.focusFigureUseCase = focusFigureUseCase
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
            
            self.figures = result
            self.figureStatus = .complete
            
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
                let height = self.focusFigureUseCase.pdfSharedData.document!.page(at: 0)!.bounds(for: .mediaBox).height
                var paperInfo = self.focusFigureUseCase.pdfSharedData.paperInfo!
                
                await self.focusFigureUseCase.excute(process: .processFulltextDocument, url: url) {
                    switch $0 {
                    case .success(let layout):
                        DispatchQueue.main.async {
                            self.figures = layout.toEntities(pageHeight: height)
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
        
        // 인덱스가 유효한지 확인
        guard index >= 0 && index < self.figures.count else {
            print("Invalid index")
            return nil
        }
        
        DispatchQueue.main.async {
            self.figures.sort { $0.page < $1.page }                    // figure와 table 페이지 순서 정렬
        }
        
        let document = PDFDocument()                                    // 새 PDFDocument 생성
        let annotation = self.figures[index]                  // 주어진 인덱스의 annotation 가져오기
        
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
