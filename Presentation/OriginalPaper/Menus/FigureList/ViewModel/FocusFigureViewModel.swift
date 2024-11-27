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
    @Published public var focusPages: [FocusAnnotation] = []
    @Published public var figures: [FigureAnnotation] = []
    @Published public var figureStatus: FigureStatus = .networkDisconnection
    @Published public var changedPageNumber: Int?
    
    @Published public var isEditFigName: Bool = false
    @Published public var selectedID: UUID?
    
    private var focusFigureUseCase: FocusFigureUseCase
    
    public var focusDocument: PDFDocument?
    
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
            var isStale = false
            let height = document!.page(at: 0)!.bounds(for: .mediaBox).height
            let result = figureList.map { $0.toEntity(pageHeight: height) }
            let focusUrl = try! URL.init(resolvingBookmarkData: paperInfo!.focusURL!, bookmarkDataIsStale: &isStale)
            
            if result.isEmpty {
                self.figureStatus = .empty
                return
            }
            
            self.focusDocument = PDFDocument(url: focusUrl)
            
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
        if self.figureStatus == .loading { return }
        
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
                            self.figures = layout.toFigureEntities(pageHeight: height)
                            self.focusPages = layout.toFocusEntities(pageHeight: height)
                            self.figureStatus = .complete
                            
                            self.saveFigures(figures: layout.toCoreData())
                            
                            let url = self.setFocusDocument(fileName: paperInfo.title)
                            
                            self.focusFigureUseCase.pdfSharedData.paperInfo!.focusURL = try? url.bookmarkData(options: .minimalBookmark)
                            paperInfo.focusURL = try? url.bookmarkData(options: .minimalBookmark)
                            
                            self.focusFigureUseCase.pdfSharedData.paperInfo!.isFigureSaved = true
                            paperInfo.isFigureSaved = true
                            
                            NotificationCenter.default.post(name: .changeHomePaperInfo, object: paperInfo, userInfo: nil)
                            
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



// MARK: 집중모드 생성 메소드
extension FocusFigureViewModel {
    private func setFocusDocument(fileName: String) -> URL {
        let tempPath = FileManager.default.temporaryDirectory
            .appending(path: "combine.pdf")
        
        let maxWidth: CGFloat = {
            var result: CGFloat = 0
            for annotation in self.focusPages {
                if annotation.position.width > result {
                    result = annotation.position.width
                }
            }
            return result
        }()
        
        let heightArray: [CGFloat] = {
            var result: [CGFloat] = []
            var headString = self.focusPages.first!.header
            
            var temp: CGFloat = 0
            
            for annotation in self.focusPages {
                if headString != annotation.header {
                    headString = annotation.header
                    result.append(temp)
                    temp = 0
                    continue
                }
                
                temp += annotation.position.height
            }
            result.append(temp)
            
            return result
        }()
        
        let annotationArray: [[FocusAnnotation]] = {
            var resultArray: [[FocusAnnotation]] = []
            
            var head = self.focusPages.first!.header
            
            var tempArray = [FocusAnnotation]()
            
            for annotation in self.focusPages {
                if annotation.header != head {
                    head = annotation.header
                    resultArray.append(tempArray)
                    tempArray.removeAll()
                    continue
                }
                
                tempArray.append(annotation)
            }
            resultArray.append(tempArray)
            return resultArray
        }()
        
        UIGraphicsBeginPDFContextToFile(tempPath.path(), .zero, nil)
        
        for (index, annotations) in annotationArray.enumerated() {
            let height = heightArray[index]
            
            UIGraphicsBeginPDFPageWithInfo(.init(origin: .zero, size: .init(width: maxWidth + 60, height: height)), nil)
            
            var currentY: CGFloat = 0
            
            for i in annotations {
                    // Render the page content
                    if let context = UIGraphicsGetCurrentContext() {
                        let page = self.focusFigureUseCase.pdfSharedData.document!
                            .page(at: i.page - 1)!.copy() as! PDFPage
                        
                        let crop = i.position
                        
                        let original = page.bounds(for: .mediaBox)
                        let croppedRect = original.intersection(crop)
                        page.displaysAnnotations = false
                        
                        page.setBounds(croppedRect, for: .mediaBox)
                        
                        context.saveGState()
                        context.translateBy(x: 30, y: currentY + i.position.height) // Adjust y-position
                        context.scaleBy(x: 1, y: -1) // Flip coordinate system
                        page.draw(with: .mediaBox, to: context) // Draw the page
                        context.restoreGState()
                    }

                    // Move to the next page's position
                currentY += i.position.height
            }
        }
        
        UIGraphicsEndPDFContext()
        
        let savingURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appending(path: "\(fileName)_combine.pdf")
        
        try! FileManager.default.moveItem(at: tempPath, to: savingURL)
        
        self.focusDocument = PDFDocument(url: savingURL)
        
        return savingURL
    }
}

extension FocusFigureViewModel {
    public func editFigTitle(at id: UUID, head: String) {
        if let index = figures.firstIndex(where: { $0.uuid == id }) {
            figures[index].head = head
            // TODO: - [무니] 살려줘
//            let figure = figures[index].toCoreData()
//            self.focusFigureUseCase.editFigures(with: figure)
        }
    }
}
