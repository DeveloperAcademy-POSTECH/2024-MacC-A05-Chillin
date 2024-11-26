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
    @Published public var figures: [FigureAnnotation] = [] {
        didSet {
            if oldValue != figures {
                updateThumbnails()
            }
        }
    }
    @Published public var documents: [PDFDocument] = []
    @Published public var figureStatus: FigureStatus = .networkDisconnection
    @Published public var changedPageNumber: Int?
    
    @Published public var isEditFigName: Bool = false
    @Published public var selectedID: UUID?
    
    // 올가미 툴
    @Published var isCaptureMode: Bool = false
    
    let publisher = NotificationCenter.default.publisher(for: .isPDFCaptured)
    
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
    
    // figure 리스트가 바뀔 때 마다 썸네일을 업데이트하는 메서드
    private func updateThumbnails() {
        // 정렬
        DispatchQueue.main.async {
            self.figures.sort { $0.page < $1.page }
        }
        
        documents.removeAll()
        
        for index in figures.indices {
            if let newDocument = setFigureDocument(for: index) {
                documents.append(newDocument)
            }
        }
    }
    
    public func setFigureDocument(for index: Int) -> PDFDocument? {
        guard index >= 0 && index < self.figures.count else {
            print("Invalid index")
            return nil
        }
        
        let document = PDFDocument()
        let annotation = self.figures[index]
        
        guard let page = self.focusFigureUseCase.pdfSharedData.document?.page(at: annotation.page - 1)?.copy()
                as? PDFPage else {
            print("Failed to get page")
            return nil
        }
        
        page.displaysAnnotations = false
        
        
        let original = page.bounds(for: .mediaBox)
        let croppedRect = original.intersection(annotation.position)
        
        page.setBounds(croppedRect, for: .mediaBox)
        document.insert(page, at: 0)                       
        
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
    
    // 올가미로 새 Figure 추가하는 부분
    func isPDFCaptured() {
        self.publisher
            .sink { [weak self] in
                self?.isCaptureMode.toggle()
                
                guard let figure = $0.object as? Figure else { return }
                guard let height = self?.focusFigureUseCase.getPDFHeight() else { return }
                
                // "New" ID를 가진 Figure의 수를 계산하여 넘버링 추가
                let newFigureCount = self!.figures.filter { $0.id == "New" }.count + 1
                let updatedFigure = Figure(
                    id: figure.id,
                    head: "\(figure.head ?? "New") \(newFigureCount)", // head에 "New 1", "New 2" 형식으로 넘버링
                    label: figure.label,
                    figDesc: figure.figDesc,
                    coords: figure.coords,
                    graphicCoord: figure.graphicCoord
                )
                
                // Figure를 저장하고, figures에 변환된 엔티티를 추가
                self?.focusFigureUseCase.saveFigures(with: updatedFigure)
                self?.figures.append(updatedFigure.toEntity(pageHeight: height))
            }
            .store(in: &self.cancellables)
    }
}

extension FocusFigureViewModel {
    public func editFigTitle(at id: UUID, head: String) {
        if let index = figures.firstIndex(where: { $0.uuid == id }) {
            figures[index].head = head
            
            self.focusFigureUseCase.editFigures(with: figures[index].toDTO())
        }
    }
    
    public func deleteFigure(at id: UUID) {
        if let index = figures.firstIndex(where: { $0.uuid == id }) {
            self.figures.removeAll(where: { $0.uuid == id })
            
            self.focusFigureUseCase.deleteFigures(with: figures[index].toDTO())
        }
    }
}
