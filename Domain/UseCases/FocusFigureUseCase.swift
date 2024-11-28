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
    
    func loadCollections () -> Result<[Collection], any Error>
    
    @discardableResult
    func saveCollections (
        with collection: Collection
    ) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editCollections (
        with collection: Collection
    ) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deleteCollections (
        with collection: Collection
    ) -> Result<VoidResponse, any Error>
    
    func getPDFHeight() -> CGFloat
}



class DefaultFocusFigureUseCase: FocusFigureUseCase {
    
    public var pdfSharedData: PDFSharedData = .shared
    
    private let focusFigureRepository: FocusFigureRepository
    private let figureDataRepository: FigureDataRepository
    private let collectionDataRepository: CollectionDataRepository
    
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
        await self.focusFigureRepository.fetchFocusAndFigures(process: process, url: url) { result in
            switch result {
            case .success(let layout):
                completion(.success(layout))
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
    
    public func loadCollections() -> Result<[Collection], any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return collectionDataRepository.loadCollectionData(for: id)
    }
    
    public func saveCollections(with collection: Collection) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return collectionDataRepository.saveCollectionData(for: id, with: collection)
    }
    
    public func editCollections(with collection: Collection) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return collectionDataRepository.editFigureData(for: id, with: collection)
    }
    
    public func deleteCollections(with collection: Collection) -> Result<VoidResponse, any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return collectionDataRepository.deleteCollectionData(for: id, id: collection.id)
    }

    public func getPDFHeight() -> CGFloat {
        self.pdfSharedData.document!.page(at: 0)!.bounds(for: .mediaBox).height
    }
}
