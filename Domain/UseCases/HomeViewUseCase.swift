//
//  HomeViewUseCase.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation
import SwiftUI
import PDFKit


protocol HomeViewUseCase {
    func loadPDFs() -> Result<[PaperInfo], any Error>
    
    @discardableResult
    func savePDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deletePDF(id: UUID) -> Result<VoidResponse, any Error>
    
    func duplicatePDF(paperInfo: PaperInfo) throws -> PaperInfo?
    
    func uploadPDFFile(url: [URL], folderID: UUID?) throws -> PaperInfo?
  
    func savePDFIntoDirectory(url: URL, isSample: Bool) throws -> (Data, URL)?
    
    func uploadSamplePDFFile() -> PaperInfo?
    
    func loadFolders() -> Result<[Folder], any Error>
    
    @discardableResult
    func saveFolder(_ folder: Folder) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editFolder(_ folder: Folder) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deleteFolder(id: UUID) -> Result<VoidResponse, any Error>
}


class DefaultHomeViewUseCase: HomeViewUseCase {
    private let paperDataRepository: PaperDataRepository
    private let folderDataRepository: FolderDataRepository
    
    init(paperDataRepository: PaperDataRepository, folderDataRepository: FolderDataRepository) {
        self.paperDataRepository = paperDataRepository
        self.folderDataRepository = folderDataRepository
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
    
    public func deletePDF(id: UUID) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.deletePDFInfo(id: id)
    }
    
    public func uploadPDFFile(url: [URL], folderID: UUID?) throws -> PaperInfo? {
        guard let url = url.first else { return nil }
        
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        let tempDoc = PDFDocument(url: url)

        
        guard let urlData = try? self.savePDFIntoDirectory(url: url, isSample: false) else {
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
                url: urlData.0,
                folderID: folderID
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
            
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData.0,
                folderID: folderID
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
    }
    
    public func uploadSamplePDFFile() -> PaperInfo? {
        let pdfURL = Bundle.main.url(forResource: "Reazy Sample Paper", withExtension: "pdf")!
        
        let tempDoc = PDFDocument(url: pdfURL)

        let urlData = try! self.savePDFIntoDirectory(url: pdfURL, isSample: true)!
        
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
    
    public func duplicatePDF(paperInfo: PaperInfo) throws -> PaperInfo? {
        var isStale = false
        
        do {
            let originalUrl = try URL.init(resolvingBookmarkData: paperInfo.url, bookmarkDataIsStale: &isStale)
            
            if let (data, url) = try self.savePDFIntoDirectory(url: originalUrl, isSample: false) {
                
                let newPaperInfo = PaperInfo(
                    title: url.deletingPathExtension().lastPathComponent,
                    thumbnail: paperInfo.thumbnail,
                    url: data,
                    focusURL: nil,
                    lastModifiedDate: Date(),
                    isFavorite: paperInfo.isFavorite,
                    memo: paperInfo.memo,
                    isFigureSaved: paperInfo.isFigureSaved,
                    folderID: paperInfo.folderID)
                
                self.paperDataRepository.duplicatePDFInfo(id: paperInfo.id, info: newPaperInfo)
                return newPaperInfo
            }
            
            throw PDFUploadError.fileNameDuplication
        } catch {
            throw PDFUploadError.fileNameDuplication
        }
    }
    
    public func loadFolders() -> Result<[Folder], any Error> {
        self.folderDataRepository.loadFolders()
    }
    
    public func saveFolder(_ folder: Folder) -> Result<VoidResponse, any Error> {
        self.folderDataRepository.saveFolder(folder)
    }
    
    public func editFolder(_ folder: Folder) -> Result<VoidResponse, any Error> {
        self.folderDataRepository.editFolder(folder)
    }
    
    public func deleteFolder(id: UUID) -> Result<VoidResponse, any Error> {
        self.folderDataRepository.deleteFolder(id: id)
    }
      
    internal func savePDFIntoDirectory(url: URL, isSample: Bool) throws -> (Data, URL)? {
        do {
            let manager = FileManager.default
            let documentURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentURL.appending(path: url.lastPathComponent)
            
            // TODO: url 오류 대응
            if !isSample {
                guard url.startAccessingSecurityScopedResource() else { return nil }
                do { url.stopAccessingSecurityScopedResource() }
            }
            
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
