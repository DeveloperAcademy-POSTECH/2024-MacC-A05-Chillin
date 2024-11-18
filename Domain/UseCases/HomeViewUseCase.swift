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
    
    func savePDFIntoDirectory(url: URL) throws -> Data?
    
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
        
        guard url.startAccessingSecurityScopedResource() else {
            throw PDFUploadError.failedToAccessingSecurityScope
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        
        let tempDoc = PDFDocument(url: url)
        var lastComponent = url.lastPathComponent.split(separator: ".")
        lastComponent.removeLast()
        
        let title = lastComponent.joined()
        
        guard let urlData = try? self.savePDFIntoDirectory(url: url) else {
            throw PDFUploadError.fileNameDuplication
        }
        
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData!,
                url: urlData
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
            
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
    }
    
    public func uploadSamplePDFFile() -> PaperInfo? {
        let pdfURL = Bundle.main.url(forResource: "Reazy Sample Paper", withExtension: "pdf")!
        
        let tempDoc = PDFDocument(url: pdfURL)
        var lastComponent = pdfURL.lastPathComponent.split(separator: ".")
        lastComponent.removeLast()
        
        let title = lastComponent.joined()
        let urlData = try! self.savePDFIntoDirectory(url: pdfURL)!
        
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData!,
                url: urlData
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            
            return paperInfo
            
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
    }
    
    internal func savePDFIntoDirectory(url: URL) throws -> Data? {
        do {
            let manager = FileManager.default
            let documentURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentURL.appending(path: url.lastPathComponent)
            
            if manager.fileExists(atPath: fileURL.path()) {
                throw PDFUploadError.fileNameDuplication
            } else {
                try manager.copyItem(at: url, to: fileURL)
            }
            
            let urlData = try fileURL.bookmarkData(options: .minimalBookmark)
            
            return urlData
        } catch {
            print("error copying file: \(error)")
        }
        
        return nil
    }
}
