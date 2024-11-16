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
    func editPaperInfo(
        info: PaperInfo
    ) -> Result<VoidResponse, any Error>
    
}



class DefaultFocusFigureUseCase: FocusFigureUseCase {
    
    public var pdfSharedData: PDFSharedData = .shared
    
    private let focusFigureRepository: FocusFigureRepository
    private let paperDataService: FigureDataInterface = FigureDataService.shared
    
    init(
        focusFigureRepository: FocusFigureRepository
    ) {
        self.focusFigureRepository = focusFigureRepository
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
        return paperDataService.saveFigureData(for: id, with: figure)
    }
    
    public func loadFigures() -> Result<[Figure], any Error> {
        guard let id = self.pdfSharedData.paperInfo?.id else {
            return .failure(NetworkManagerError.badRequest)
        }
        
        return paperDataService.loadFigureData(for: id)
    }
    
    public func editPaperInfo(info: PaperInfo) -> Result<VoidResponse, any Error> {
        paperDataService.editPaperInfo(info: info)
    }
}



class PDFSharedData {
    static let shared = PDFSharedData()
    
    public var document: PDFDocument?
    public var paperInfo: PaperInfo?
    
    private init() { }
    
    public func makeDocument(from paperInfo: PaperInfo) {
        var isStale: Bool = false
        
        if let url = try? URL.init(resolvingBookmarkData: paperInfo.url, bookmarkDataIsStale: &isStale),
           url.startAccessingSecurityScopedResource() {
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let document = PDFDocument(url: url)
            self.document = document
            self.paperInfo = paperInfo
        }
    }
}
