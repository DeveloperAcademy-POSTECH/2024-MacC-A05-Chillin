//
//  FocusFigureUseCase.swift
//  Reazy
//
//  Created by 문인범 on 11/15/24.
//

import Foundation
import PDFKit


protocol FocusFigureUseCase {
    var pdfSharedData: PDFSharedData { get set }
    
    func excute(
        process: NetworkManager.ServiceName,
        url: URL,
        completion: @escaping (Result<PDFLayoutResponseDTO, NetworkManagerError>) -> Void
    ) async
    
    func stopTask()
    
    func loadFigures () -> Result<[Figure], any Error>
    
    @discardableResult
    func saveFigures (
        with figure: Figure
    ) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editFigures (
        with figure: Figure
    ) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editPaperInfo(
        info: PaperInfo
    ) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deleteFigures (
        with figure: Figure
    ) -> Result<VoidResponse, any Error>
    
    func makeFocusDocument(
        focusAnnotations: [FocusAnnotation],
        fileName: String,
        completion: @escaping (URL) -> Void
    )

    func loadCollections () -> Result<[Figure], any Error>
    
    @discardableResult
    func saveCollections (
        with collection: Figure
    ) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editCollections (
        with collection: Figure
    ) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deleteCollections (
        with collection: Figure
    ) -> Result<VoidResponse, any Error>
    
    func getPDFHeight() -> CGFloat
}



class DefaultFocusFigureUseCase: FocusFigureUseCase {
    
    public var pdfSharedData: PDFSharedData = .shared
    
    private let focusFigureRepository: FocusFigureRepository
    private let figureDataRepository: FigureDataRepository
    private let collectionDataRepository: CollectionDataRepository
    
    private var currentTask: Task<Void, any Error>?
    
    init(
        focusFigureRepository: FocusFigureRepository,
        figureDataRepository: FigureDataRepository,
        collectionDataRepository: CollectionDataRepository
    ) {
        self.focusFigureRepository = focusFigureRepository
        self.figureDataRepository = figureDataRepository
        self.collectionDataRepository = collectionDataRepository
    }
    
    public func excute(
        process: NetworkManager.ServiceName,
        url: URL,
        completion: @escaping (Result<PDFLayoutResponseDTO, NetworkManagerError>) -> Void
    ) async {
        self.currentTask = Task {
            await self.focusFigureRepository.fetchFocusAndFigures(process: process, url: url) { result in
                switch result {
                case .success(let layout):
                    completion(.success(layout))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    public func stopTask() {
        self.currentTask?.cancel()
    }
    
    public func saveFigures(with figure: Figure) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        return figureDataRepository.saveFigureData(for: id, with: figure)
    }
    
    public func loadFigures() -> Result<[Figure], any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return figureDataRepository.loadFigureData(for: id)
    }
    
    public func editFigures(with figure: Figure) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return figureDataRepository.editFigureData(for: id, with: figure)
    }
    
    public func editPaperInfo(info: PaperInfo) -> Result<VoidResponse, any Error> {
        figureDataRepository.editPaperInfo(info: info)
    }
    
    public func deleteFigures(with figure: Figure) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return figureDataRepository.deleteFigureData(for: id, id: figure.id)
    }
    
    public func makeFocusDocument(
        focusAnnotations: [FocusAnnotation],
        fileName: String,
        completion: @escaping (URL) -> Void
    ) {
        let tempPath = FileManager.default.temporaryDirectory
            .appending(path: "combine.pdf")
        
        let widthArray: [CGFloat] = {
            var result = [CGFloat]()
            
            var tempHead = focusAnnotations.first!.header
            var tempWidth: CGFloat = -1
            
            for annotation in focusAnnotations {
                if tempHead != annotation.header {
                    result.append(tempWidth)
                    tempWidth = -1
                    tempHead = annotation.header
                }
                tempWidth = max(tempWidth, annotation.position.width)
            }
            
            result.append(tempWidth)
            return result
        }()
        
        let heightArray: [CGFloat] = {
            var result: [CGFloat] = []
            var headString = focusAnnotations.first!.header
            
            var temp: CGFloat = 0
            
            for annotation in focusAnnotations {
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
            
            var head = focusAnnotations.first!.header
            
            var tempArray = [FocusAnnotation]()
            
            for annotation in focusAnnotations {
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
        
        DispatchQueue.global().async {
            UIGraphicsBeginPDFContextToFile(tempPath.path(), .zero, nil)
            
            for (index, annotations) in annotationArray.enumerated() {
                let width = widthArray[index]
                let height = heightArray[index]
                
                UIGraphicsBeginPDFPageWithInfo(.init(origin: .zero, size: .init(width: width + 60, height: height)), nil)
                
                var currentY: CGFloat = 0
                
                for i in annotations {
                    // Render the page content
                    if let context = UIGraphicsGetCurrentContext() {
                        let page = self.pdfSharedData.document!
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
            
            completion(savingURL)
        }
    }
    
    public func loadCollections() -> Result<[Figure], any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return collectionDataRepository.loadCollectionData(for: id)
    }
    
    public func saveCollections(with collection: Figure) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return collectionDataRepository.saveCollectionData(for: id, with: collection)
    }
    
    public func editCollections(with collection: Figure) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return collectionDataRepository.editFigureData(for: id, with: collection)
    }
    
    public func deleteCollections(with collection: Figure) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return collectionDataRepository.deleteCollectionData(for: id, id: collection.id)
    }
    
    public func getPDFHeight() -> CGFloat {
        self.pdfSharedData.document!.page(at: 0)!.bounds(for: .mediaBox).height
    }
}
