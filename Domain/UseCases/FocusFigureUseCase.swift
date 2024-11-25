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
    
    func getPDFHeight() -> CGFloat
}



class DefaultFocusFigureUseCase: FocusFigureUseCase {
    
    public var pdfSharedData: PDFSharedData = .shared
    
    private let focusFigureRepository: FocusFigureRepository
    private let figureDataRepository: FigureDataRepository
    
    init(
        focusFigureRepository: FocusFigureRepository,
        figureDataRepository: FigureDataRepository
    ) {
        self.focusFigureRepository = focusFigureRepository
        self.figureDataRepository = figureDataRepository
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
    
    public func getPDFHeight() -> CGFloat {
        self.pdfSharedData.document!.page(at: 0)!.bounds(for: .mediaBox).height
    }
}
