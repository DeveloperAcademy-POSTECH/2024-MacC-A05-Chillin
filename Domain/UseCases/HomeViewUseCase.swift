//
//  HomeViewUseCase.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation
import PDFKit


protocol HomeViewUseCase {
    func loadPDFs() -> Result<[PaperInfo], any Error>
    
    @discardableResult
    func savePDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deletePDFs(id: [UUID]) -> Result<VoidResponse, any Error>
    
    func savePDFIntoDirectory(url: URL) throws -> (Data, URL)?
    
    func uploadPDFFile(url: [URL]) throws -> PaperInfo?
    func uploadSamplePDFFile() -> PaperInfo?
}


class DefaultHomeViewUseCase: HomeViewUseCase {
    private let paperDataRepository: PaperDataRepository
    
    init(paperDataRepository: PaperDataRepository) {
        self.paperDataRepository = paperDataRepository
    }
    
    public func loadPDFs() -> Result<[PaperInfo], any Error> {
        self.paperDataRepository.loadPDFInfo()
    }
    
    public func savePDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.savePDFInfo(info)
    }
    
    public func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.editPDFInfo(info)
    }
    
    public func deletePDFs(id: [UUID]) -> Result<VoidResponse, any Error> {
        var result: Result<VoidResponse, any Error>? = nil
        id.forEach {
            switch self.paperDataRepository.deletePDFInfo(id: $0) {
            case .success(let success):
                result = .success(success)
            case .failure(let error):
                result = .failure(error)
                break
            }
        }
        return result!
    }
    
    public func uploadPDFFile(url: [URL]) throws -> PaperInfo? {
        guard let url = url.first else { return nil }
        
        let tempDoc = PDFDocument(url: url)

        
        guard let urlData = try? self.savePDFIntoDirectory(url: url) else {
            throw PDFUploadError.fileNameDuplication
        }
        
        var lastComponent = urlData.1.lastPathComponent.split(separator: ".")
        lastComponent.removeLast()
        
        let title = lastComponent.joined()
        
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData!,
                url: urlData.0
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
            
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData.0
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
    }
    
    public func uploadSamplePDFFile() -> PaperInfo? {
        let pdfURL = Bundle.main.url(forResource: "Reazy Sample Paper", withExtension: "pdf")!
        
        let tempDoc = PDFDocument(url: pdfURL)

        let urlData = try! self.savePDFIntoDirectory(url: pdfURL)!
        
        var lastComponent = pdfURL.lastPathComponent.split(separator: ".")
        lastComponent.removeLast()
        
        let title = lastComponent.joined()
        
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData!,
                url: urlData.0
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            
            return paperInfo
            
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData.0
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
    }
    
    internal func savePDFIntoDirectory(url: URL) throws -> (Data, URL)? {
        do {
            let manager = FileManager.default
            let documentURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentURL.appending(path: url.lastPathComponent)
            
            if manager.fileExists(atPath: fileURL.path()) {
                var dupNum = 1
                
                
                var lastComponent = url.lastPathComponent.split(separator: ".")
                lastComponent.removeLast()
                
                
                while dupNum < 100 {
                    let tempURL = documentURL.appending(path: lastComponent.joined() + "(\(dupNum)).pdf")
                    
                    if !manager.fileExists(atPath: tempURL.path()) {
                        try manager.copyItem(at: url, to: tempURL)
                        return try (tempURL.bookmarkData(options: .minimalBookmark), tempURL)
                    }
                    
                    if dupNum == 99 {
                        throw PDFUploadError.fileNameDuplication
                    }
                    
                    dupNum += 1
                }
                
                
            } else {
                try manager.copyItem(at: url, to: fileURL)
            }
            
            let urlData = try fileURL.bookmarkData(options: .minimalBookmark)
            
            return (urlData, fileURL)
        } catch {
            print("error copying file: \(error)")
        }
        
        return nil
    }
}
