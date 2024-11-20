//
//  PDFInfoMenuUseCase.swift
//  Reazy
//
//  Created by 김예림 on 11/20/24.
//

import Foundation
import PDFKit

protocol PDFInfoMenuUseCase {
    var pdfSharedData: PDFSharedData { get set }
    
    @discardableResult
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deletePDFs(id: UUID) -> Result<VoidResponse, any Error>
}


class DefaultPDFInfoMenuUseCase: PDFInfoMenuUseCase {
    
    var pdfSharedData: PDFSharedData = .shared
    
    private let paperDataRepository: PaperDataRepository
    
    init(paperDataRepository: PaperDataRepository) {
        self.paperDataRepository = paperDataRepository
    }
    
    public func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.editPDFInfo(info)
    }
    
    public func deletePDFs(id: UUID) -> Result<VoidResponse, any Error> {
        var result: Result<VoidResponse, any Error>? = nil
        switch self.paperDataRepository.deletePDFInfo(id: id) {
        case .success(let success):
            result = .success(success)
        case .failure(let error):
            result = .failure(error)
            break
        }
        
        return result!
    }
}
